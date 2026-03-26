package com.islamicdaydial.watchface.core

import org.junit.Assert.assertEquals
import org.junit.Test
import java.util.Date

class NightMarkersTest {

    private val lastMaghrib = Date(1742052600000L) // 2025-03-15T15:30:00.000Z
    private val fajr = Date(1742090400000L)       // 2025-03-16T02:00:00.000Z

    @Test
    fun getLastThirdStart_returnsFajrMinusOneThirdOfNight() {
        val lastThird = getLastThirdStart(lastMaghrib, fajr)
        val nightDurationMs = fajr.time - lastMaghrib.time
        val expected = Date(fajr.time - nightDurationMs / 3)
        assertEquals(expected.time, lastThird.time)
    }

    @Test
    fun getLastThirdStart_isAfterTwoThirdsPoint() {
        val lastThird = getLastThirdStart(lastMaghrib, fajr)
        val twoThirdsPoint = Date(lastMaghrib.time + ((fajr.time - lastMaghrib.time) * 2 / 3))
        assertEquals(twoThirdsPoint.time, lastThird.time)
    }

    @Test
    fun getLastThirdStart_isBeforeFajr() {
        val lastThird = getLastThirdStart(lastMaghrib, fajr)
        assert(lastThird.time < fajr.time)
    }
}
