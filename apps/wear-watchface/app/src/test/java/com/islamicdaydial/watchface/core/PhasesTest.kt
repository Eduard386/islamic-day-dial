package com.islamicdaydial.watchface.core

import org.junit.Assert.assertEquals
import org.junit.Test
import java.util.Date

class PhasesTest {

    private val timeline = ComputedTimeline(
        lastMaghrib = Date(1742052600000L),   // 2025-03-15T15:30:00.000Z
        isha = Date(1742058000000L),         // 2025-03-15T17:00:00.000Z
        islamicMidnight = Date(1742069100000L),
        lastThirdStart = Date(1742074200000L),
        fajr = Date(1742090400000L),         // 2025-03-16T02:00:00.000Z
        sunrise = Date(1742094900000L),
        dhuhr = Date(1742116500000L),
        asr = Date(1742127000000L),
        nextMaghrib = Date(1742139000000L)   // 2025-03-16T15:30:00.000Z
    )

    @Test
    fun getCurrentPhase_returnsMaghribToIshaRightAfterMaghrib() {
        val now = Date(1742052660000L) // 15:31
        assertEquals(IslamicPhaseId.MAGHRIB_TO_ISHA, getCurrentPhase(now, timeline))
    }

    @Test
    fun getCurrentPhase_returnsIshaToMidnightAfterIsha() {
        val now = Date(1742059800000L) // 17:30
        assertEquals(IslamicPhaseId.ISHA_TO_MIDNIGHT, getCurrentPhase(now, timeline))
    }

    @Test
    fun getCurrentPhase_returnsMidnightToLastThirdAfterIslamicMidnight() {
        val now = Date(1742070000000L) // 21:00
        assertEquals(IslamicPhaseId.MIDNIGHT_TO_LAST_THIRD, getCurrentPhase(now, timeline))
    }

    @Test
    fun getCurrentPhase_returnsLastThirdToFajrAfterLastThirdStart() {
        val now = Date(1742076000000L) // 23:00
        assertEquals(IslamicPhaseId.LAST_THIRD_TO_FAJR, getCurrentPhase(now, timeline))
    }

    @Test
    fun getCurrentPhase_returnsFajrToSunriseAfterFajr() {
        val now = Date(1742092200000L) // 02:30
        assertEquals(IslamicPhaseId.FAJR_TO_SUNRISE, getCurrentPhase(now, timeline))
    }

    @Test
    fun getCurrentPhase_returnsSunriseToDhuhrAfterSunrise() {
        val now = Date(1742101200000L) // 05:00
        assertEquals(IslamicPhaseId.SUNRISE_TO_DHUHR, getCurrentPhase(now, timeline))
    }

    @Test
    fun getCurrentPhase_returnsDhuhrToAsrAfterDhuhr() {
        val now = Date(1742119200000L) // 10:00
        assertEquals(IslamicPhaseId.DHUHR_TO_ASR, getCurrentPhase(now, timeline))
    }

    @Test
    fun getCurrentPhase_returnsAsrToMaghribAfterAsr() {
        val now = Date(1742130000000L) // 13:00
        assertEquals(IslamicPhaseId.ASR_TO_MAGHRIB, getCurrentPhase(now, timeline))
    }

    @Test
    fun getCurrentPhase_returnsMaghribToIshaExactlyAtMaghrib() {
        assertEquals(IslamicPhaseId.MAGHRIB_TO_ISHA, getCurrentPhase(timeline.lastMaghrib, timeline))
    }

    @Test
    fun getCurrentPhase_returnsIshaToMidnightExactlyAtIsha() {
        assertEquals(IslamicPhaseId.ISHA_TO_MIDNIGHT, getCurrentPhase(timeline.isha, timeline))
    }

    @Test
    fun getNextTransition_returnsIshaWhenInMaghribToIshaPhase() {
        val now = Date(1742054400000L) // 16:00
        val (id, at) = getNextTransition(now, timeline)
        assertEquals("isha", id)
        assertEquals(timeline.isha.time, at.time)
    }

    @Test
    fun getNextTransition_returnsFajrWhenInLastThirdToFajrPhase() {
        val now = Date(1742086800000L) // 01:00
        val (id, at) = getNextTransition(now, timeline)
        assertEquals("fajr", id)
        assertEquals(timeline.fajr.time, at.time)
    }

    @Test
    fun getNextTransition_returnsNextMaghribWhenInAsrToMaghribPhase() {
        val now = Date(1742133600000L) // 14:00
        val (id, at) = getNextTransition(now, timeline)
        assertEquals("maghrib", id)
        assertEquals(timeline.nextMaghrib.time, at.time)
    }
}
