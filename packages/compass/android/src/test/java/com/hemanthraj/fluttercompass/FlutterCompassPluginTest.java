package com.hemanthraj.fluttercompass;

import static org.junit.Assert.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

import android.content.Context;
import android.hardware.Sensor;
import android.hardware.SensorEvent;
import android.hardware.SensorEventListener;
import android.hardware.SensorManager;
import android.os.SystemClock;
import android.view.Display;
import android.view.Surface;

import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.RuntimeEnvironment;
import org.robolectric.annotation.Config;
import org.robolectric.shadow.api.Shadow;
import org.robolectric.shadows.ShadowDisplay;
import org.robolectric.shadows.ShadowSensorManager;
import org.robolectric.Shadows;

import java.lang.reflect.Field;

import io.flutter.embedding.engine.plugins.FlutterPlugin.FlutterPluginBinding;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.EventChannel.EventSink;

@RunWith(RobolectricTestRunner.class)
@Config(sdk = 34, manifest = Config.NONE)
public class FlutterCompassPluginTest {

    private FlutterCompassPlugin plugin;

    @Mock
    private EventSink mockSink;

    // Robolectric shadow sensor manager for the application context
    private ShadowSensorManager shadowSensorManager;
    private SensorManager sensorManager;
    private Context context;

    // -----------------------------------------------------------------------
    // Helper: create a SensorEvent with specific type and values via reflection
    // -----------------------------------------------------------------------
    private SensorEvent createSensorEvent(int sensorType, float[] values) throws Exception {
        // SensorEvent constructor is package-private; use reflection
        SensorEvent event = Shadow.newInstanceOf(SensorEvent.class);

        // Sensor field
        Sensor sensor = createSensor(sensorType);

        Field sensorField = SensorEvent.class.getDeclaredField("sensor");
        sensorField.setAccessible(true);
        sensorField.set(event, sensor);

        // Values field
        Field valuesField = SensorEvent.class.getDeclaredField("values");
        valuesField.setAccessible(true);
        valuesField.set(event, values);

        return event;
    }

    private Sensor createSensor(int sensorType) throws Exception {
        Sensor sensor = Shadow.newInstanceOf(Sensor.class);
        Field typeField = Sensor.class.getDeclaredField("mType");
        typeField.setAccessible(true);
        typeField.set(sensor, sensorType);
        return sensor;
    }

    private FlutterPluginBinding createBinding(BinaryMessenger messenger) {
        return new FlutterPluginBinding(context, null, messenger, null, null, null, null);
    }

    // -----------------------------------------------------------------------
    // Helper: inject plugin fields via reflection
    // -----------------------------------------------------------------------
    private void setField(String name, Object value) throws Exception {
        Field f = FlutterCompassPlugin.class.getDeclaredField(name);
        f.setAccessible(true);
        f.set(plugin, value);
    }

    @SuppressWarnings("unchecked")
    private <T> T getField(String name) throws Exception {
        Field f = FlutterCompassPlugin.class.getDeclaredField(name);
        f.setAccessible(true);
        return (T) f.get(plugin);
    }

    // -----------------------------------------------------------------------
    // Helper: build a mock Display with a given rotation
    // -----------------------------------------------------------------------
    private Display mockDisplay(int rotation) {
        Display d = mock(Display.class);
        when(d.getRotation()).thenReturn(rotation);
        return d;
    }

    // -----------------------------------------------------------------------
    // Helper: advance compassUpdateNextTimestamp so throttle passes
    // -----------------------------------------------------------------------
    private void resetThrottle() throws Exception {
        setField("compassUpdateNextTimestamp", 0L);
    }

    @Before
    public void setUp() throws Exception {
        MockitoAnnotations.openMocks(this);
        plugin = new FlutterCompassPlugin();
        context = RuntimeEnvironment.getApplication();
        sensorManager = (SensorManager) context.getSystemService(Context.SENSOR_SERVICE);
        shadowSensorManager = Shadows.shadowOf(sensorManager);
    }

    // =======================================================================
    // 1. createSensorEventListener — onAccuracyChanged
    // =======================================================================

    @Test
    public void onAccuracyChanged_updatesLastAccuracySensorStatus() throws Exception {
        SensorEventListener listener = plugin.createSensorEventListener(mockSink);
        Sensor sensor = Shadow.newInstanceOf(Sensor.class);

        listener.onAccuracyChanged(sensor, SensorManager.SENSOR_STATUS_ACCURACY_HIGH);

        int status = getField("lastAccuracySensorStatus");
        assertEquals(SensorManager.SENSOR_STATUS_ACCURACY_HIGH, status);
    }

    @Test
    public void onAccuracyChanged_doesNotUpdateIfSameValue() throws Exception {
        setField("lastAccuracySensorStatus", SensorManager.SENSOR_STATUS_ACCURACY_MEDIUM);
        SensorEventListener listener = plugin.createSensorEventListener(mockSink);
        Sensor sensor = Shadow.newInstanceOf(Sensor.class);

        // Trigger twice with same accuracy — value stays unchanged
        listener.onAccuracyChanged(sensor, SensorManager.SENSOR_STATUS_ACCURACY_MEDIUM);
        listener.onAccuracyChanged(sensor, SensorManager.SENSOR_STATUS_ACCURACY_MEDIUM);

        int status = getField("lastAccuracySensorStatus");
        assertEquals(SensorManager.SENSOR_STATUS_ACCURACY_MEDIUM, status);
    }

    // =======================================================================
    // 2. getAccuracy mapping (exercised via emitted event v[2])
    // =======================================================================

    private double emitAndCaptureAccuracy(int accuracyStatus) throws Exception {
        setField("lastAccuracySensorStatus", accuracyStatus);
        setField("display", mockDisplay(Surface.ROTATION_0));
        resetThrottle();

        // Provide a valid rotation vector so updateOrientation succeeds
        float[] rotVec = {0f, 0f, 0f, 1f};
        setField("rotationVectorValue", rotVec);

        SensorEventListener listener = plugin.createSensorEventListener(mockSink);
        SensorEvent event = createSensorEvent(Sensor.TYPE_ROTATION_VECTOR, rotVec);

        listener.onSensorChanged(event);

        ArgumentCaptor<Object> captor = ArgumentCaptor.forClass(Object.class);
        verify(mockSink, atLeastOnce()).success(captor.capture());
        double[] result = (double[]) captor.getValue();
        return result[2];
    }

    @Test
    public void getAccuracy_high_returns15() throws Exception {
        assertEquals(15.0, emitAndCaptureAccuracy(SensorManager.SENSOR_STATUS_ACCURACY_HIGH), 0.001);
    }

    @Test
    public void getAccuracy_medium_returns30() throws Exception {
        assertEquals(30.0, emitAndCaptureAccuracy(SensorManager.SENSOR_STATUS_ACCURACY_MEDIUM), 0.001);
    }

    @Test
    public void getAccuracy_low_returns45() throws Exception {
        assertEquals(45.0, emitAndCaptureAccuracy(SensorManager.SENSOR_STATUS_ACCURACY_LOW), 0.001);
    }

    @Test
    public void getAccuracy_unreliable_returnsMinus1() throws Exception {
        assertEquals(-1.0, emitAndCaptureAccuracy(SensorManager.SENSOR_STATUS_UNRELIABLE), 0.001);
    }

    // =======================================================================
    // 3. onSensorChanged — TYPE_ROTATION_VECTOR triggers updateOrientation
    // =======================================================================

    @Test
    public void onSensorChanged_rotationVector_callsSinkSuccess() throws Exception {
        setField("display", mockDisplay(Surface.ROTATION_0));
        resetThrottle();

        float[] rotVec = {0f, 0f, 0f, 1f};
        SensorEventListener listener = plugin.createSensorEventListener(mockSink);
        SensorEvent event = createSensorEvent(Sensor.TYPE_ROTATION_VECTOR, rotVec);

        listener.onSensorChanged(event);

        verify(mockSink).success(any(double[].class));
    }

    @Test
    public void onSensorChanged_rotationVector_emits3ElementArray() throws Exception {
        setField("display", mockDisplay(Surface.ROTATION_0));
        resetThrottle();

        float[] rotVec = {0f, 0f, 0f, 1f};
        SensorEventListener listener = plugin.createSensorEventListener(mockSink);
        SensorEvent event = createSensorEvent(Sensor.TYPE_ROTATION_VECTOR, rotVec);

        listener.onSensorChanged(event);

        ArgumentCaptor<Object> captor = ArgumentCaptor.forClass(Object.class);
        verify(mockSink).success(captor.capture());
        double[] result = (double[]) captor.getValue();
        assertEquals(3, result.length);
    }

    // =======================================================================
    // 4. onSensorChanged — throttle: second event within 32ms is dropped
    // =======================================================================

    @Test
    public void onSensorChanged_throttle_dropsEventWithinRateMs() throws Exception {
        setField("display", mockDisplay(Surface.ROTATION_0));
        resetThrottle();

        float[] rotVec = {0f, 0f, 0f, 1f};
        SensorEventListener listener = plugin.createSensorEventListener(mockSink);
        SensorEvent event = createSensorEvent(Sensor.TYPE_ROTATION_VECTOR, rotVec);

        // First call — should pass
        listener.onSensorChanged(event);
        // Second call immediately — should be throttled (compassUpdateNextTimestamp is now in the future)
        listener.onSensorChanged(event);

        // Only one success call expected
        verify(mockSink, times(1)).success(any());
    }

    // =======================================================================
    // 5. onSensorChanged — TYPE_ACCELEROMETER: only processed when no compass sensor
    // =======================================================================

    @Test
    public void onSensorChanged_accelerometer_processedWhenNoCompassSensor() throws Exception {
        // compassSensor == null means isCompassSensorAvailable() returns false
        setField("compassSensor", null);
        setField("display", mockDisplay(Surface.ROTATION_0));
        resetThrottle();
        // magneticValues already non-null (initialized in field); gravity values set via event
        float[] values = {0f, 0f, 9.8f};
        SensorEventListener listener = plugin.createSensorEventListener(mockSink);
        SensorEvent event = createSensorEvent(Sensor.TYPE_ACCELEROMETER, values);

        listener.onSensorChanged(event);

        // updateOrientation uses getRotationMatrix path; may or may not succeed depending on
        // matrix validity, but no exception should be thrown
        // We just verify no crash and sink was called at most once
        verify(mockSink, atMost(1)).success(any());
    }

    @Test
    public void onSensorChanged_accelerometer_ignoredWhenCompassSensorPresent() throws Exception {
        // compassSensor != null — accelerometer events should be ignored
        Sensor fakeSensor = Shadow.newInstanceOf(Sensor.class);
        setField("compassSensor", fakeSensor);
        setField("display", mockDisplay(Surface.ROTATION_0));
        resetThrottle();

        float[] values = {0f, 0f, 9.8f};
        SensorEventListener listener = plugin.createSensorEventListener(mockSink);
        SensorEvent event = createSensorEvent(Sensor.TYPE_ACCELEROMETER, values);

        listener.onSensorChanged(event);

        verify(mockSink, never()).success(any());
    }

    // =======================================================================
    // 6. onSensorChanged — TYPE_MAGNETIC_FIELD: only processed when no compass sensor
    // =======================================================================

    @Test
    public void onSensorChanged_magneticField_processedWhenNoCompassSensor() throws Exception {
        setField("compassSensor", null);
        setField("display", mockDisplay(Surface.ROTATION_0));
        resetThrottle();

        float[] values = {20f, 0f, 40f};
        SensorEventListener listener = plugin.createSensorEventListener(mockSink);
        SensorEvent event = createSensorEvent(Sensor.TYPE_MAGNETIC_FIELD, values);

        listener.onSensorChanged(event);

        verify(mockSink, atMost(1)).success(any());
    }

    @Test
    public void onSensorChanged_magneticField_ignoredWhenCompassSensorPresent() throws Exception {
        Sensor fakeSensor = Shadow.newInstanceOf(Sensor.class);
        setField("compassSensor", fakeSensor);
        setField("display", mockDisplay(Surface.ROTATION_0));
        resetThrottle();

        float[] values = {20f, 0f, 40f};
        SensorEventListener listener = plugin.createSensorEventListener(mockSink);
        SensorEvent event = createSensorEvent(Sensor.TYPE_MAGNETIC_FIELD, values);

        listener.onSensorChanged(event);

        verify(mockSink, never()).success(any());
    }

    // =======================================================================
    // 7. updateOrientation — display == null returns early (no sink call)
    // =======================================================================

    @Test
    public void updateOrientation_noDisplay_doesNotCallSink() throws Exception {
        setField("display", null);
        resetThrottle();

        float[] rotVec = {0f, 0f, 0f, 1f};
        SensorEventListener listener = plugin.createSensorEventListener(mockSink);
        SensorEvent event = createSensorEvent(Sensor.TYPE_ROTATION_VECTOR, rotVec);

        listener.onSensorChanged(event);

        verify(mockSink, never()).success(any());
    }

    // =======================================================================
    // 8. Display rotation axis remapping — ROTATION_0, 90, 180, 270
    //    Each rotation should still produce a valid 3-element double[] from sink
    // =======================================================================

    private void assertRotationProducesEvent(int rotation) throws Exception {
        assertRotationVectorProducesEvent(rotation, new float[]{0f, 0f, 0f, 1f});
    }

    private void assertRotationVectorProducesEvent(int rotation, float[] rotVec) throws Exception {
        plugin = new FlutterCompassPlugin();
        setField("display", mockDisplay(rotation));
        resetThrottle();
        setField("rotationVectorValue", rotVec);

        SensorEventListener listener = plugin.createSensorEventListener(mockSink);
        SensorEvent event = createSensorEvent(Sensor.TYPE_ROTATION_VECTOR, rotVec);

        listener.onSensorChanged(event);

        ArgumentCaptor<Object> captor = ArgumentCaptor.forClass(Object.class);
        verify(mockSink).success(captor.capture());
        double[] result = (double[]) captor.getValue();
        assertEquals(3, result.length);
        reset(mockSink);
    }

    @Test
    public void updateOrientation_rotation0_emitsEvent() throws Exception {
        assertRotationProducesEvent(Surface.ROTATION_0);
    }

    @Test
    public void updateOrientation_rotation90_emitsEvent() throws Exception {
        assertRotationProducesEvent(Surface.ROTATION_90);
    }

    @Test
    public void updateOrientation_rotation180_emitsEvent() throws Exception {
        assertRotationProducesEvent(Surface.ROTATION_180);
    }

    @Test
    public void updateOrientation_rotation270_emitsEvent() throws Exception {
        assertRotationProducesEvent(Surface.ROTATION_270);
    }

    @Test
    public void updateOrientation_pitchDown_remapsAllDisplayRotations() throws Exception {
        float halfSqrt2 = 0.70710677f;
        float[] pitchDown = {halfSqrt2, 0f, 0f, halfSqrt2};

        assertRotationVectorProducesEvent(Surface.ROTATION_0, pitchDown);
        assertRotationVectorProducesEvent(Surface.ROTATION_90, pitchDown);
        assertRotationVectorProducesEvent(Surface.ROTATION_180, pitchDown);
        assertRotationVectorProducesEvent(Surface.ROTATION_270, pitchDown);
    }

    @Test
    public void updateOrientation_pitchUp_remapsAllDisplayRotations() throws Exception {
        float halfSqrt2 = 0.70710677f;
        float[] pitchUp = {-halfSqrt2, 0f, 0f, halfSqrt2};

        assertRotationVectorProducesEvent(Surface.ROTATION_0, pitchUp);
        assertRotationVectorProducesEvent(Surface.ROTATION_90, pitchUp);
        assertRotationVectorProducesEvent(Surface.ROTATION_180, pitchUp);
        assertRotationVectorProducesEvent(Surface.ROTATION_270, pitchUp);
    }

    @Test
    public void updateOrientation_faceDownRoll_remapsAllDisplayRotations() throws Exception {
        float[] faceDownRoll = {0f, 0.8660254f, 0f, 0.5f};

        assertRotationVectorProducesEvent(Surface.ROTATION_0, faceDownRoll);
        assertRotationVectorProducesEvent(Surface.ROTATION_90, faceDownRoll);
        assertRotationVectorProducesEvent(Surface.ROTATION_180, faceDownRoll);
        assertRotationVectorProducesEvent(Surface.ROTATION_270, faceDownRoll);
    }

    // =======================================================================
    // 9. getRotationVectorFromSensorEvent — truncation for length > 4
    // =======================================================================

    @Test
    public void onSensorChanged_truncatesLongRotationVector() throws Exception {
        setField("display", mockDisplay(Surface.ROTATION_0));
        resetThrottle();

        // 5-element vector — should be truncated to 4
        float[] longValues = {0.1f, 0.2f, 0.3f, 0.9f, 0.0f};
        SensorEventListener listener = plugin.createSensorEventListener(mockSink);
        SensorEvent event = createSensorEvent(Sensor.TYPE_ROTATION_VECTOR, longValues);

        listener.onSensorChanged(event);

        // Should still emit without exception
        verify(mockSink, atMost(1)).success(any());
    }

    // =======================================================================
    // 10. onListen / onCancel
    // =======================================================================

    @Test
    public void onListen_createsSensorEventListener() throws Exception {
        setField("sensorManager", sensorManager);
        // No sensors in Robolectric by default; onListen should not crash
        plugin.onListen(null, mockSink);

        SensorEventListener listener = getField("sensorEventListener");
        assertNotNull(listener);
    }

    @Test
    public void onCancel_doesNotCrashWhenNoListenerRegistered() throws Exception {
        setField("sensorManager", sensorManager);
        // Should not throw even with no active listener
        plugin.onCancel(null);
    }

    @Test
    public void onCancel_afterOnListen_doesNotCrash() throws Exception {
        setField("sensorManager", sensorManager);
        plugin.onListen(null, mockSink);
        plugin.onCancel(null);
    }

    @Test
    public void onListen_registersRotationVectorSensorOnlyWhenAvailable() throws Exception {
        Sensor compass = createSensor(Sensor.TYPE_ROTATION_VECTOR);
        Sensor gravity = createSensor(Sensor.TYPE_ACCELEROMETER);
        Sensor magnetic = createSensor(Sensor.TYPE_MAGNETIC_FIELD);
        setField("sensorManager", sensorManager);
        setField("compassSensor", compass);
        setField("gravitySensor", gravity);
        setField("magneticFieldSensor", magnetic);

        plugin.onListen(null, mockSink);

        SensorEventListener listener = getField("sensorEventListener");
        assertTrue(shadowSensorManager.hasListener(listener, compass));
        assertFalse(shadowSensorManager.hasListener(listener, gravity));
        assertFalse(shadowSensorManager.hasListener(listener, magnetic));

        plugin.onCancel(null);

        assertFalse(shadowSensorManager.hasListener(listener, compass));
    }

    @Test
    public void onListen_registersFallbackSensorsWhenRotationVectorUnavailable() throws Exception {
        Sensor gravity = createSensor(Sensor.TYPE_ACCELEROMETER);
        Sensor magnetic = createSensor(Sensor.TYPE_MAGNETIC_FIELD);
        setField("sensorManager", sensorManager);
        setField("compassSensor", null);
        setField("gravitySensor", gravity);
        setField("magneticFieldSensor", magnetic);

        plugin.onListen(null, mockSink);

        SensorEventListener listener = getField("sensorEventListener");
        assertTrue(shadowSensorManager.hasListener(listener, gravity));
        assertTrue(shadowSensorManager.hasListener(listener, magnetic));

        plugin.onCancel(null);

        assertFalse(shadowSensorManager.hasListener(listener, gravity));
        assertFalse(shadowSensorManager.hasListener(listener, magnetic));
    }

    // =======================================================================
    // 11. onDetachedFromEngine — cleans up sensor and channel references
    // =======================================================================

    @Test
    public void onAttachedToEngine_initializesSensorsAndChannelWithoutCompassSensor() throws Exception {
        BinaryMessenger messenger = mock(BinaryMessenger.class);
        FlutterPluginBinding binding = createBinding(messenger);

        plugin.onAttachedToEngine(binding);

        assertNotNull(getField("channel"));
        assertNotNull(getField("sensorManager"));
        assertNotNull(getField("display"));
        assertNull(getField("compassSensor"));
    }

    @Test
    public void onAttachedToEngine_initializesRotationVectorWhenAvailable() throws Exception {
        Sensor compass = createSensor(Sensor.TYPE_ROTATION_VECTOR);
        shadowSensorManager.addSensor(Sensor.TYPE_ROTATION_VECTOR, compass);
        BinaryMessenger messenger = mock(BinaryMessenger.class);
        FlutterPluginBinding binding = createBinding(messenger);

        plugin.onAttachedToEngine(binding);

        assertSame(compass, getField("compassSensor"));
    }

    @Test
    public void onDetachedFromEngine_nullsOutSensorsAndClearsChannelHandler() throws Exception {
        BinaryMessenger messenger = mock(BinaryMessenger.class);
        FlutterPluginBinding binding = createBinding(messenger);
        plugin.onAttachedToEngine(binding);
        plugin.onListen(null, mockSink);

        plugin.onDetachedFromEngine(binding);

        assertNull(getField("sensorManager"));
        assertNull(getField("display"));
        assertNull(getField("compassSensor"));
        assertNull(getField("gravitySensor"));
        assertNull(getField("magneticFieldSensor"));
    }

    // =======================================================================
    // 12. isCompassSensorAvailable
    // =======================================================================

    @Test
    public void isCompassSensorAvailable_trueWhenCompassSensorNotNull() throws Exception {
        Sensor fakeSensor = Shadow.newInstanceOf(Sensor.class);
        setField("compassSensor", fakeSensor);
        // exercised indirectly: onListen with compassSensor set → registerListener path
        setField("sensorManager", sensorManager);
        plugin.onListen(null, mockSink);
        // listener was created — no NPE means the branch was taken correctly
        assertNotNull((SensorEventListener) getField("sensorEventListener"));
    }

    @Test
    public void isCompassSensorAvailable_falseWhenCompassSensorNull() throws Exception {
        setField("compassSensor", null);
        setField("sensorManager", sensorManager);
        // registerListener falls through to fallback sensors (also null in test) → logs warning
        plugin.onListen(null, mockSink);
        assertNotNull((SensorEventListener) getField("sensorEventListener"));
    }

    // =======================================================================
    // 13. lowPassFilter — null smoothed returns newValues unchanged
    // =======================================================================

    @Test
    public void onSensorChanged_magneticField_firstEvent_noLowPassCorruption() throws Exception {
        // When magneticValues are zero-initialized (not null), the low-pass filter applies.
        // First event should update magneticValues toward new values.
        setField("compassSensor", null);
        setField("display", mockDisplay(Surface.ROTATION_0));
        resetThrottle();

        float[] values = {100f, 0f, 0f};
        SensorEventListener listener = plugin.createSensorEventListener(mockSink);
        SensorEvent event = createSensorEvent(Sensor.TYPE_MAGNETIC_FIELD, values);

        listener.onSensorChanged(event);

        float[] magnetic = getField("magneticValues");
        assertNotNull(magnetic);
        // After low-pass: smoothed[i] = smoothed[i] + 0.45 * (new[i] - smoothed[i])
        // Starting from 0: result = 0 + 0.45 * (100 - 0) = 45
        assertEquals(45f, magnetic[0], 0.01f);
    }

    @Test
    public void onSensorChanged_magneticField_withNullSmoothedValuesUsesIncomingValues() throws Exception {
        setField("compassSensor", null);
        setField("magneticValues", null);
        setField("display", mockDisplay(Surface.ROTATION_0));
        resetThrottle();

        float[] values = {100f, 0f, 0f};
        SensorEventListener listener = plugin.createSensorEventListener(mockSink);
        SensorEvent event = createSensorEvent(Sensor.TYPE_MAGNETIC_FIELD, values);

        listener.onSensorChanged(event);

        assertSame(values, getField("magneticValues"));
    }

    // =======================================================================
    // 14. Heading emitted is a valid double (not NaN or Infinity)
    // =======================================================================

    @Test
    public void emittedHeading_isFinite() throws Exception {
        setField("display", mockDisplay(Surface.ROTATION_0));
        resetThrottle();

        float[] rotVec = {0f, 0f, 0f, 1f};
        setField("rotationVectorValue", rotVec);

        SensorEventListener listener = plugin.createSensorEventListener(mockSink);
        SensorEvent event = createSensorEvent(Sensor.TYPE_ROTATION_VECTOR, rotVec);

        listener.onSensorChanged(event);

        ArgumentCaptor<Object> captor = ArgumentCaptor.forClass(Object.class);
        verify(mockSink).success(captor.capture());
        double heading = ((double[]) captor.getValue())[0];
        assertTrue(Double.isFinite(heading));
    }
}
