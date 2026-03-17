package com.islamicdaydial.watchface.core

import org.junit.Assert.assertEquals
import org.junit.Test
import java.util.Date

class NightMarkersTest {

    private val lastMaghrib = Date(1742052600000L) // 2025-03-15T15:30:00.000Z
    private val fajr = Date(1742090400000L)       // 2025-03-16T02:00:00.000Z

    @Test
    fun getIslamicMidnight_returnsMidpointBetweenMaghribAndFajr() {
        val midnight = getIslamicMidnight(lastMaghrib, fajr)
        val nightDurationMs = fajr.time - lastMaghrib.time
        val expected = Date(lastMaghrib.time + nightDurationMs / 2)
        assertEquals(expected.time, midnight.time)
    }

    @Test
    fun getIslamicMidnight_handlesShortSummerNights() {
        val shortMaghrib = Date(1721061000000L) // 2024-07-15T17:30:00.000Z
        val shortFajr = Date(1721093400000L)   // 2024-07-16T00:30:00.000Z
        val midnight = getIslamicMidnight(shortMaghrib, shortFajr)
        val nightMs = shortFajr.time - shortMaghrib.time
        val expected = Date(shortMaghrib.time + nightMs / 2)
        assertEquals(expected.time, midnight.time)
    }

    @Test
    fun getLastThirdStart_returnsFajrMinusOneThirdOfNight() {
        val lastThird = getLastThirdStart(lastMaghrib, fajr)
        val nightDurationMs = fajr.time - lastMaghrib.time
        val expected = Date(fajr.time - nightDurationMs / 3)
        assertEquals(expected.time, lastThird.time)
    }

    @Test
    fun getLastThirdStart_isAfterIslamicMidnight() {
        val midnight = getIslamicMidnight(lastMaghrib, fajr)
        val lastThird = getLastThirdStart(lastMaghrib, fajr)
        assert(lastThird.time > midnight.time)
    }

    @Test
    fun getLastThirdStart_isBeforeFajr() {
        val lastThird = getLastThirdStart(lastMaghrib, fajr)
        assert(lastThird.time < fajr.time)
    }
}
