package ml.medyas.qibla

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorManager
import androidx.annotation.NonNull;
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/** QiblaPlugin */
class QiblaPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var context: Context
    private lateinit var channel: MethodChannel

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, METHOD_CHANNEL)
        context = flutterPluginBinding.applicationContext
        channel.setMethodCallHandler(this)
    }

    companion object {
        private const val METHOD_CHANNEL = "ml.medyas.qibla"
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when(call.method) {
            // Check whether the device supports the TYPE_ROTATION_VECTOR sensor
            "androidSupportSensor" -> {
                val sensorManager = context.getSystemService(Context.SENSOR_SERVICE) as SensorManager
                val sensor = sensorManager.getDefaultSensor(Sensor.TYPE_ROTATION_VECTOR) ?: null
                result.success(sensor != null)
            }
            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}
