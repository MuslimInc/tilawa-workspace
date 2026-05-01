package com.tilawa.app.prayer

import android.content.Intent
import android.media.AudioManager
import io.mockk.*
import org.junit.Assert.*
import org.junit.Test

class PlaybackLogicTest {
    private val mockStrings = mockk<StringProvider>()
    private val mockService = mockk<ServiceActions>(relaxed = true)
    private val mockAnalytics = mockk<PrayerAnalytics>(relaxed = true)
    private val logic = PlaybackLogic(mockStrings, mockService, mockAnalytics)

    @Test
    fun `handleIntent PLAY logs event`() {
        val intent = mockk<Intent>()
        every { intent.action } returns "com.tilawa.app.prayer.ACTION_PLAY"
        every { intent.getStringExtra(any()) } returns "fajr"
        
        logic.handleIntent(intent)
        verify { mockAnalytics.logEvent(PrayerEvents.PLAYBACK_STARTED, any()) }
    }

    @Test
    fun `handleIntent STOP`() {
        val intent = mockk<Intent>()
        every { intent.action } returns "com.tilawa.app.prayer.ACTION_STOP"

        val action = logic.handleIntent(intent)
        assertEquals(PlaybackAction.STOP, action)
    }

    @Test
    fun `handleIntent PLAY`() {
        val intent = mockk<Intent>()
        every { intent.action } returns "com.tilawa.app.prayer.ACTION_PLAY"
        every { intent.getStringExtra("prayer_name") } returns "fajr"

        val action = logic.handleIntent(intent) as PlaybackAction.PLAY
        assertEquals("fajr", action.prayerName)
    }

    @Test
    fun `handleIntent null intent defaults to PLAY`() {
        val action = logic.handleIntent(null)
        assertTrue(action is PlaybackAction.PLAY)
    }

    @Test
    fun `handleIntent returns NONE for unknown action`() {
        val intent = mockk<Intent>()
        every { intent.action } returns "unknown"
        assertEquals(PlaybackAction.NONE, logic.handleIntent(intent))
    }

    @Test
    fun `getNotificationTitle for all prayers`() {
        val prayers = listOf("fajr", "dhuhr", "asr", "maghrib", "isha", "sunrise")
        prayers.forEach { name ->
            every { mockStrings.getString("prayer_$name") } returns "$name Prayer"
            assertEquals("$name Prayer", logic.getNotificationTitle(name))
        }
    }

    @Test
    fun `getNotificationTitle for unknown prayer returns capitalized name`() {
        assertEquals("Custom", logic.getNotificationTitle("custom"))
    }

    @Test
    fun `getNotificationTitle for empty prayer returns app name`() {
        every { mockStrings.getString("app_name") } returns "Tilawa"
        assertEquals("Tilawa", logic.getNotificationTitle(""))
    }

    @Test
    fun `onAudioFocusChange stop on focus loss`() {
        logic.onAudioFocusChange(AudioManager.AUDIOFOCUS_LOSS)
        verify { mockService.stopPlayback() }
    }

    @Test
    fun `onAudioFocusChange stop on focus loss transient`() {
        logic.onAudioFocusChange(AudioManager.AUDIOFOCUS_LOSS_TRANSIENT)
        verify { mockService.stopPlayback() }
    }

    @Test
    fun `onAudioFocusChange stop on focus loss transient can duck`() {
        logic.onAudioFocusChange(AudioManager.AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK)
        verify { mockService.stopPlayback() }
    }

    @Test
    fun `onAudioFocusChange ignore focus gain`() {
        logic.onAudioFocusChange(AudioManager.AUDIOFOCUS_GAIN)
        verify(exactly = 0) { mockService.stopPlayback() }
    }
}
