package com.islamicdaydial.watchface.core

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import java.util.Date

class RingTest {

    private val lastMaghrib = Date(1742052600000L) // 2025-03-15T15:30:00.000Z
    private val nextMaghrib = Date(1742139000000L) // 2025-03-16T15:30:00.000Z

    @Test
    fun getIslamicDayProgress_returns0AtLastMaghrib() {
        assertEquals(0.0, getIslamicDayProgress(lastMaghrib, lastMaghrib, nextMaghrib), 1e-10)
    }

    @Test
    fun getIslamicDayProgress_returns1AtNextMaghrib() {
        assertEquals(1.0, getIslamicDayProgress(nextMaghrib, lastMaghrib, nextMaghrib), 1e-10)
    }

    @Test
    fun getIslamicDayProgress_returns05AtMidpoint() {
        val mid = Date((lastMaghrib.time + nextMaghrib.time) / 2)
        assertEquals(0.5, getIslamicDayProgress(mid, lastMaghrib, nextMaghrib), 1e-10)
    }

    @Test
    fun getIslamicDayProgress_clampsTo0ForTimesBeforeLastMaghrib() {
        val before = Date(lastMaghrib.time - 60000)
        assertEquals(0.0, getIslamicDayProgress(before, lastMaghrib, nextMaghrib), 1e-10)
    }

    @Test
    fun getIslamicDayProgress_clampsTo1ForTimesAfterNextMaghrib() {
        val after = Date(nextMaghrib.time + 60000)
        assertEquals(1.0, getIslamicDayProgress(after, lastMaghrib, nextMaghrib), 1e-10)
    }

    @Test
    fun timestampToAngle_returns0AtLastMaghrib() {
        assertEquals(0.0, timestampToAngle(lastMaghrib, lastMaghrib, nextMaghrib), 1e-5)
    }

    @Test
    fun timestampToAngle_returns360AtNextMaghrib() {
        assertEquals(360.0, timestampToAngle(nextMaghrib, lastMaghrib, nextMaghrib), 1e-5)
    }

    @Test
    fun timestampToAngle_returns180AtMidpoint() {
        val mid = Date((lastMaghrib.time + nextMaghrib.time) / 2)
        assertEquals(180.0, timestampToAngle(mid, lastMaghrib, nextMaghrib), 1e-5)
    }

    @Test
    fun getMarkers_returns7Markers() {
        val timeline = ComputedTimeline(
            lastMaghrib = lastMaghrib,
            isha = Date(1742058000000L),
            islamicMidnight = Date(1742069100000L),
            lastThirdStart = Date(1742074200000L),
            fajr = Date(1742090400000L),
            sunrise = Date(1742094900000L),
            dhuhr = Date(1742116500000L),
            asr = Date(1742127000000L),
            nextMaghrib = nextMaghrib
        )
        val markers = getMarkers(timeline)
        assertEquals(7, markers.size)
    }

    @Test
    fun getMarkers_firstMarkerIsMaghribAt0() {
        val timeline = ComputedTimeline(
            lastMaghrib = lastMaghrib,
            isha = Date(1742058000000L),
            islamicMidnight = Date(1742069100000L),
            lastThirdStart = Date(1742074200000L),
            fajr = Date(1742090400000L),
            sunrise = Date(1742094900000L),
            dhuhr = Date(1742116500000L),
            asr = Date(1742127000000L),
            nextMaghrib = nextMaghrib
        )
        val markers = getMarkers(timeline)
        assertEquals("maghrib", markers[0].id)
        assertEquals(0.0, markers[0].angleDeg, 1e-5)
        assertEquals("primary", markers[0].kind)
    }

    @Test
    fun getMarkers_markersInAscendingAngleOrder() {
        val timeline = ComputedTimeline(
            lastMaghrib = lastMaghrib,
            isha = Date(1742058000000L),
            islamicMidnight = Date(1742069100000L),
            lastThirdStart = Date(1742074200000L),
            fajr = Date(1742090400000L),
            sunrise = Date(1742094900000L),
            dhuhr = Date(1742116500000L),
            asr = Date(1742127000000L),
            nextMaghrib = nextMaghrib
        )
        val markers = getMarkers(timeline)
        for (i in 1 until markers.size) {
            assertTrue(markers[i].angleDeg > markers[i - 1].angleDeg)
        }
    }

    @Test
    fun getMarkers_secondaryMarkerIsLastThirdStart() {
        val timeline = ComputedTimeline(
            lastMaghrib = lastMaghrib,
            isha = Date(1742058000000L),
            islamicMidnight = Date(1742069100000L),
            lastThirdStart = Date(1742074200000L),
            fajr = Date(1742090400000L),
            sunrise = Date(1742094900000L),
            dhuhr = Date(1742116500000L),
            asr = Date(1742127000000L),
            nextMaghrib = nextMaghrib
        )
        val markers = getMarkers(timeline)
        val secondary = markers.filter { it.kind == "secondary" }
        assertEquals(listOf("last_third_start"), secondary.map { it.id })
    }

    @Test
    fun getRingSegments_returns8Segments() {
        val timeline = ComputedTimeline(
            lastMaghrib = lastMaghrib,
            isha = Date(1742058000000L),
            islamicMidnight = Date(1742069100000L),
            lastThirdStart = Date(1742074200000L),
            fajr = Date(1742090400000L),
            sunrise = Date(1742094900000L),
            dhuhr = Date(1742116500000L),
            asr = Date(1742127000000L),
            nextMaghrib = nextMaghrib
        )
        val segments = getRingSegments(timeline)
        assertEquals(8, segments.size)
    }

    @Test
    fun getRingSegments_firstSegmentStartsAt0() {
        val timeline = ComputedTimeline(
            lastMaghrib = lastMaghrib,
            isha = Date(1742058000000L),
            islamicMidnight = Date(1742069100000L),
            lastThirdStart = Date(1742074200000L),
            fajr = Date(1742090400000L),
            sunrise = Date(1742094900000L),
            dhuhr = Date(1742116500000L),
            asr = Date(1742127000000L),
            nextMaghrib = nextMaghrib
        )
        val segments = getRingSegments(timeline)
        assertEquals(0.0, segments[0].startAngleDeg, 1e-5)
    }

    @Test
    fun getRingSegments_lastSegmentEndsAt360() {
        val timeline = ComputedTimeline(
            lastMaghrib = lastMaghrib,
            isha = Date(1742058000000L),
            islamicMidnight = Date(1742069100000L),
            lastThirdStart = Date(1742074200000L),
            fajr = Date(1742090400000L),
            sunrise = Date(1742094900000L),
            dhuhr = Date(1742116500000L),
            asr = Date(1742127000000L),
            nextMaghrib = nextMaghrib
        )
        val segments = getRingSegments(timeline)
        assertEquals(360.0, segments[segments.size - 1].endAngleDeg, 1e-5)
    }

    @Test
    fun getRingSegments_segmentsAreContiguous() {
        val timeline = ComputedTimeline(
            lastMaghrib = lastMaghrib,
            isha = Date(1742058000000L),
            islamicMidnight = Date(1742069100000L),
            lastThirdStart = Date(1742074200000L),
            fajr = Date(1742090400000L),
            sunrise = Date(1742094900000L),
            dhuhr = Date(1742116500000L),
            asr = Date(1742127000000L),
            nextMaghrib = nextMaghrib
        )
        val segments = getRingSegments(timeline)
        for (i in 1 until segments.size) {
            assertEquals(
                segments[i - 1].endAngleDeg,
                segments[i].startAngleDeg,
                1e-5
            )
        }
    }
}
