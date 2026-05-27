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
    fun `handleIntent PLAY returns PLAY action`() {
        val intent = mockk<Intent>()
        every { intent.action } returns "com.tilawa.app.prayer.ACTION_PLAY"
        every { intent.getStringExtra(any()) } returns "fajr"
        every { intent.getLongExtra(any(), any()) } returns 0L
        
        val action = logic.handleIntent(intent)
        assertTrue(action is PlaybackAction.PLAY)
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
        every { intent.getStringExtra(AdhanScheduler.EXTRA_PRAYER_NAME) } returns "fajr"
        every { intent.getStringExtra(AdhanScheduler.EXTRA_PRAYER_KEY) } returns "fajr"
        every { intent.getStringExtra(AdhanScheduler.EXTRA_SOUND) } returns "adhan_fajr"
        every { intent.getLongExtra(AdhanScheduler.EXTRA_SCHEDULED_MS, 0L) } returns 1000L
        every { intent.getLongExtra("receiver_time", 0L) } returns 1100L
        
        val action = logic.handleIntent(intent) as PlaybackAction.PLAY
        assertEquals("fajr", action.prayerName)
        assertEquals("adhan_fajr", action.sound)
        assertEquals(1000L, action.scheduledMs)
        assertEquals(1100L, action.receiverTime)
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
        every { mockStrings.getString("app_name") } returns "Rattil"
        assertEquals("Rattil", logic.getNotificationTitle(""))
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
