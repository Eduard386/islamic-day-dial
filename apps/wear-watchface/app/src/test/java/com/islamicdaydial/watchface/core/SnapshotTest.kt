package com.islamicdaydial.watchface.core

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import java.util.Date
import java.util.TimeZone

class SnapshotTest {

    @Before
    fun setUp() {
        TimeZone.setDefault(TimeZone.getTimeZone("Europe/Istanbul"))
    }

    @Test
    fun computeIslamicDaySnapshot_producesValidSnapshotForIstanbulSummerAfternoon() {
        // 2024-07-15T11:00:00Z = 14:00 Istanbul (before Maghrib)
        val now = Date(1721041200000L)
        val location = Location(41.0082, 28.9784)
        val snapshot = computeIslamicDaySnapshot(now, location, "Europe/Istanbul")

        assertValidSnapshot(snapshot)
        assertEquals(IslamicPhaseId.DHUHR_TO_ASR, snapshot.currentPhase)
    }

    @Test
    fun computeIslamicDaySnapshot_producesValidSnapshotForMeccaEvening() {
        TimeZone.setDefault(TimeZone.getTimeZone("Asia/Riyadh"))
        // 2025-03-15T15:30:00Z = 18:30 Riyadh
        val now = Date(1742052600000L)
        val location = Location(21.4225, 39.8262)
        val snapshot = computeIslamicDaySnapshot(now, location, "Asia/Riyadh")

        assertValidSnapshot(snapshot)
    }

    @Test
    fun computeIslamicDaySnapshot_timelineMarkersAreStrictlyOrdered() {
        val now = Date(1721041200000L)
        val location = Location(41.0082, 28.9784)
        val snapshot = computeIslamicDaySnapshot(now, location, "Europe/Istanbul")

        val tl = snapshot.timeline
        val times = listOf(
            tl.lastMaghrib, tl.isha, tl.islamicMidnight, tl.lastThirdStart,
            tl.fajr, tl.sunrise, tl.dhuhr, tl.asr, tl.nextMaghrib
        )
        for (i in 1 until times.size) {
            assertTrue(times[i].time > times[i - 1].time)
        }
    }

    @Test
    fun computeIslamicDaySnapshot_ringSegmentsCoverFull360() {
        val now = Date(1721041200000L)
        val location = Location(41.0082, 28.9784)
        val snapshot = computeIslamicDaySnapshot(now, location, "Europe/Istanbul")

        val segments = snapshot.ringSegments
        assertEquals(0.0, segments[0].startAngleDeg, 0.001)
        assertEquals(360.0, segments[segments.size - 1].endAngleDeg, 0.001)
    }

    @Test
    fun computeIslamicDaySnapshot_ringMarkersFirstIsMaghribAt0() {
        val now = Date(1721041200000L)
        val location = Location(41.0082, 28.9784)
        val snapshot = computeIslamicDaySnapshot(now, location, "Europe/Istanbul")

        assertEquals("maghrib", snapshot.ringMarkers[0].id)
        assertEquals(0.0, snapshot.ringMarkers[0].angleDeg, 0.001)
    }

    private fun assertValidSnapshot(snapshot: ComputedIslamicDay) {
        assertTrue(snapshot.hijriDate.day in 1..30)
        assertTrue(snapshot.hijriDate.monthNumber in 1..12)
        assertTrue(snapshot.hijriDate.year >= 1400)
        assertTrue(snapshot.hijriDate.monthNameEn.isNotEmpty())

        assertTrue(snapshot.ringProgress in 0.0..1.0)
        assertEquals(8, snapshot.ringMarkers.size)
        assertEquals(8, snapshot.ringSegments.size)

        assertTrue(snapshot.countdownMs >= 0)
        assertTrue(snapshot.nextTransitionId.isNotEmpty())

        val tl = snapshot.timeline
        assertTrue(tl.lastMaghrib.time < tl.isha.time)
        assertTrue(tl.isha.time < tl.islamicMidnight.time)
        assertTrue(tl.islamicMidnight.time < tl.lastThirdStart.time)
        assertTrue(tl.lastThirdStart.time < tl.fajr.time)
        assertTrue(tl.fajr.time < tl.sunrise.time)
        assertTrue(tl.sunrise.time < tl.dhuhr.time)
        assertTrue(tl.dhuhr.time < tl.asr.time)
        assertTrue(tl.asr.time < tl.nextMaghrib.time)
    }
}
