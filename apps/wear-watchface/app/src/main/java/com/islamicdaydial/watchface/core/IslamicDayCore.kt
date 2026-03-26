package com.islamicdaydial.watchface.core

import com.batoulapps.adhan.CalculationMethod
import com.batoulapps.adhan.Coordinates
import com.batoulapps.adhan.PrayerTimes
import com.github.msarhan.ummalqura.calendar.UmmalquraCalendar
import java.util.Calendar
import java.util.Date
import java.util.TimeZone

/**
 * Kotlin port of @islamic-day-dial/core.
 * Computes Islamic day snapshot: Hijri date, prayer times, phases, ring geometry.
 */

data class Location(val latitude: Double, val longitude: Double)

data class HijriDate(
    val day: Int,
    val monthNumber: Int,
    val monthNameEn: String,
    val year: Int
)

data class PrayerTimesData(
    val fajr: Date,
    val sunrise: Date,
    val dhuhr: Date,
    val asr: Date,
    val maghrib: Date,
    val isha: Date
)

data class ComputedTimeline(
    val lastMaghrib: Date,
    val isha: Date,
    val lastThirdStart: Date,
    val fajr: Date,
    val sunrise: Date,
    val dhuhr: Date,
    val asr: Date,
    val nextMaghrib: Date
)

enum class IslamicPhaseId {
    MAGHRIB_TO_ISHA,
    ISHA_TO_LAST_THIRD,
    LAST_THIRD_TO_FAJR,
    FAJR_TO_SUNRISE,
    SUNRISE_TO_DHUHR,
    DHUHR_TO_ASR,
    ASR_TO_MAGHRIB
}

data class RingMarker(
    val id: String,
    val timestamp: Date,
    val angleDeg: Double,
    val kind: String
)

data class RingSegment(
    val id: IslamicPhaseId,
    val start: Date,
    val end: Date,
    val startAngleDeg: Double,
    val endAngleDeg: Double
)

data class ComputedIslamicDay(
    val hijriDate: HijriDate,
    val timeline: ComputedTimeline,
    val currentPhase: IslamicPhaseId,
    val nextTransitionId: String,
    val nextTransitionAt: Date,
    val countdownMs: Long,
    val ringProgress: Double,
    val ringMarkers: List<RingMarker>,
    val ringSegments: List<RingSegment>
)

private val MONTH_NAMES_EN = arrayOf(
    "Muharram", "Safar", "Rabi al-Awwal", "Rabi al-Thani",
    "Jumada al-Ula", "Jumada al-Thani", "Rajab", "Shaban",
    "Ramadan", "Shawwal", "Dhul Qadah", "Dhul Hijjah"
)

private val PHASE_BOUNDARIES = listOf(
    Triple(IslamicPhaseId.MAGHRIB_TO_ISHA, "lastMaghrib", "isha"),
    Triple(IslamicPhaseId.ISHA_TO_LAST_THIRD, "isha", "lastThirdStart"),
    Triple(IslamicPhaseId.LAST_THIRD_TO_FAJR, "lastThirdStart", "fajr"),
    Triple(IslamicPhaseId.FAJR_TO_SUNRISE, "fajr", "sunrise"),
    Triple(IslamicPhaseId.SUNRISE_TO_DHUHR, "sunrise", "dhuhr"),
    Triple(IslamicPhaseId.DHUHR_TO_ASR, "dhuhr", "asr"),
    Triple(IslamicPhaseId.ASR_TO_MAGHRIB, "asr", "nextMaghrib")
)

private val MARKER_DEFS = listOf(
    Triple("maghrib", "lastMaghrib", "primary"),
    Triple("isha", "isha", "primary"),
    Triple("last_third_start", "lastThirdStart", "secondary"),
    Triple("fajr", "fajr", "primary"),
    Triple("sunrise", "sunrise", "primary"),
    Triple("dhuhr", "dhuhr", "primary"),
    Triple("asr", "asr", "primary")
)

fun getPrayerTimesForDate(date: Date, location: Location): PrayerTimesData {
    val cal = Calendar.getInstance(TimeZone.getDefault()).apply { time = date }
    val coords = Coordinates(location.latitude, location.longitude)
    val params = CalculationMethod.UMM_AL_QURA.getParameters().apply {
        // Isha by twilight disappearance (per hadith), not fixed 90-min interval
        ishaInterval = 0
        ishaAngle = 15.0
    }
    val dateComponents = com.batoulapps.adhan.data.DateComponents(
        cal.get(Calendar.YEAR),
        cal.get(Calendar.MONTH) + 1,
        cal.get(Calendar.DAY_OF_MONTH)
    )
    val prayerTimes = PrayerTimes(coords, dateComponents, params)
    return PrayerTimesData(
        fajr = prayerTimes.fajr,
        sunrise = prayerTimes.sunrise,
        dhuhr = prayerTimes.dhuhr,
        asr = prayerTimes.asr,
        maghrib = prayerTimes.maghrib,
        isha = prayerTimes.isha
    )
}

fun addDays(date: Date, days: Int): Date {
    val cal = Calendar.getInstance().apply { time = date; add(Calendar.DAY_OF_MONTH, days) }
    return cal.time
}

fun getLastThirdStart(lastMaghrib: Date, fajr: Date): Date {
    val nightDuration = fajr.time - lastMaghrib.time
    return Date(fajr.time - nightDuration / 3)
}

fun buildTimeline(
    now: Date,
    todayPT: PrayerTimesData,
    yesterdayPT: PrayerTimesData,
    tomorrowPT: PrayerTimesData
): ComputedTimeline {
    val afterMaghrib = now.time >= todayPT.maghrib.time
    val nightPT = if (afterMaghrib) todayPT else yesterdayPT
    val dayPT = if (afterMaghrib) tomorrowPT else todayPT
    return ComputedTimeline(
        lastMaghrib = nightPT.maghrib,
        isha = nightPT.isha,
        lastThirdStart = getLastThirdStart(nightPT.maghrib, dayPT.fajr),
        fajr = dayPT.fajr,
        sunrise = dayPT.sunrise,
        dhuhr = dayPT.dhuhr,
        asr = dayPT.asr,
        nextMaghrib = dayPT.maghrib
    )
}

fun getHijriDate(gregorianDate: Date): HijriDate {
    val uq = UmmalquraCalendar().apply { time = gregorianDate }
    val day = uq.get(Calendar.DAY_OF_MONTH)
    val month = uq.get(Calendar.MONTH) + 1
    val year = uq.get(Calendar.YEAR)
    return HijriDate(
        day = day,
        monthNumber = month,
        monthNameEn = MONTH_NAMES_EN.getOrElse(month - 1) { "?" },
        year = year
    )
}

fun getIslamicDayHijriDate(now: Date, todayMaghrib: Date): HijriDate {
    return if (now.time >= todayMaghrib.time) {
        getHijriDate(addDays(now, 1))
    } else {
        getHijriDate(now)
    }
}

fun getCurrentPhase(now: Date, timeline: ComputedTimeline): IslamicPhaseId {
    val t = now.time
    for ((id, startKey, endKey) in PHASE_BOUNDARIES) {
        val start = when (startKey) {
            "lastMaghrib" -> timeline.lastMaghrib
            "isha" -> timeline.isha
            "lastThirdStart" -> timeline.lastThirdStart
            "fajr" -> timeline.fajr
            "sunrise" -> timeline.sunrise
            "dhuhr" -> timeline.dhuhr
            "asr" -> timeline.asr
            else -> timeline.lastMaghrib
        }.time
        val end = when (endKey) {
            "isha" -> timeline.isha
            "lastThirdStart" -> timeline.lastThirdStart
            "fajr" -> timeline.fajr
            "sunrise" -> timeline.sunrise
            "dhuhr" -> timeline.dhuhr
            "asr" -> timeline.asr
            "nextMaghrib" -> timeline.nextMaghrib
            else -> timeline.nextMaghrib
        }.time
        if (t >= start && t < end) return id
    }
    return IslamicPhaseId.ASR_TO_MAGHRIB
}

fun getNextTransition(now: Date, timeline: ComputedTimeline): Pair<String, Date> {
    val ordered = listOf(
        "isha" to timeline.isha,
        "last_third_start" to timeline.lastThirdStart,
        "fajr" to timeline.fajr,
        "sunrise" to timeline.sunrise,
        "dhuhr" to timeline.dhuhr,
        "asr" to timeline.asr,
        "maghrib" to timeline.nextMaghrib
    )
    for ((id, at) in ordered) {
        if (at.time > now.time) return id to at
    }
    return "maghrib" to timeline.nextMaghrib
}

/** Sub-period boundaries: duha 20 min after sunrise, midday = last 5 min before dhuhr */
private const val DUHA_START_MS = 20L * 60 * 1000
private const val MIDDAY_START_BEFORE_DHUHR_MS = 5L * 60 * 1000

/** Target for countdown: always the start of the next sector. Mirrors packages/core countdown.ts */
fun getCountdownTarget(now: Date, timeline: ComputedTimeline): Date {
    val t = now.time
    val phase = getCurrentPhase(now, timeline)
    val duhaStart = timeline.sunrise.time + DUHA_START_MS
    val duhaEnd = timeline.dhuhr.time - MIDDAY_START_BEFORE_DHUHR_MS

    return when (phase) {
        IslamicPhaseId.MAGHRIB_TO_ISHA -> timeline.isha
        IslamicPhaseId.ISHA_TO_LAST_THIRD, IslamicPhaseId.LAST_THIRD_TO_FAJR -> timeline.fajr
        IslamicPhaseId.FAJR_TO_SUNRISE -> timeline.sunrise
        IslamicPhaseId.SUNRISE_TO_DHUHR -> when {
            t < duhaStart -> Date(duhaStart)
            t < duhaEnd -> Date(duhaEnd)
            else -> timeline.dhuhr
        }
        IslamicPhaseId.DHUHR_TO_ASR -> timeline.asr
        IslamicPhaseId.ASR_TO_MAGHRIB -> timeline.nextMaghrib
    }
}

fun formatCountdown(ms: Long): String {
    if (ms <= 0) return "00:00:00"
    val totalSeconds = (ms / 1000).toInt()
    val hours = totalSeconds / 3600
    val minutes = (totalSeconds % 3600) / 60
    val seconds = totalSeconds % 60
    return "%02d:%02d:%02d".format(hours, minutes, seconds)
}

fun getIslamicDayProgress(now: Date, lastMaghrib: Date, nextMaghrib: Date): Double {
    val total = nextMaghrib.time - lastMaghrib.time
    if (total <= 0) return 0.0
    val elapsed = now.time - lastMaghrib.time
    return (elapsed.toDouble() / total).coerceIn(0.0, 1.0)
}

fun timestampToAngle(timestamp: Date, lastMaghrib: Date, nextMaghrib: Date): Double {
    return getIslamicDayProgress(timestamp, lastMaghrib, nextMaghrib) * 360
}

fun getMarkers(timeline: ComputedTimeline): List<RingMarker> {
    return MARKER_DEFS.map { (id, key, kind) ->
        val ts = when (key) {
            "lastMaghrib" -> timeline.lastMaghrib
            "isha" -> timeline.isha
            "lastThirdStart" -> timeline.lastThirdStart
            "fajr" -> timeline.fajr
            "sunrise" -> timeline.sunrise
            "dhuhr" -> timeline.dhuhr
            "asr" -> timeline.asr
            else -> timeline.lastMaghrib
        }
        RingMarker(id, ts, timestampToAngle(ts, timeline.lastMaghrib, timeline.nextMaghrib), kind)
    }
}

fun getRingSegments(timeline: ComputedTimeline): List<RingSegment> {
    return PHASE_BOUNDARIES.map { (id, startKey, endKey) ->
        val start = when (startKey) {
            "lastMaghrib" -> timeline.lastMaghrib
            "isha" -> timeline.isha
            "lastThirdStart" -> timeline.lastThirdStart
            "fajr" -> timeline.fajr
            "sunrise" -> timeline.sunrise
            "dhuhr" -> timeline.dhuhr
            "asr" -> timeline.asr
            else -> timeline.lastMaghrib
        }
        val end = when (endKey) {
            "isha" -> timeline.isha
            "lastThirdStart" -> timeline.lastThirdStart
            "fajr" -> timeline.fajr
            "sunrise" -> timeline.sunrise
            "dhuhr" -> timeline.dhuhr
            "asr" -> timeline.asr
            "nextMaghrib" -> timeline.nextMaghrib
            else -> timeline.nextMaghrib
        }
        RingSegment(
            id,
            start,
            end,
            timestampToAngle(start, timeline.lastMaghrib, timeline.nextMaghrib),
            timestampToAngle(end, timeline.lastMaghrib, timeline.nextMaghrib)
        )
    }
}

fun computeIslamicDaySnapshot(
    now: Date,
    location: Location,
    timezone: String
): ComputedIslamicDay {
    val todayPT = getPrayerTimesForDate(now, location)
    val yesterdayPT = getPrayerTimesForDate(addDays(now, -1), location)
    val tomorrowPT = getPrayerTimesForDate(addDays(now, 1), location)
    val timeline = buildTimeline(now, todayPT, yesterdayPT, tomorrowPT)
    val hijriDate = getIslamicDayHijriDate(now, todayPT.maghrib)
    val currentPhase = getCurrentPhase(now, timeline)
    val (nextId, nextAt) = getNextTransition(now, timeline)
    val countdownTarget = getCountdownTarget(now, timeline)
    val countdownMs = (countdownTarget.time - now.time).coerceAtLeast(0L)
    val progress = getIslamicDayProgress(now, timeline.lastMaghrib, timeline.nextMaghrib)
    val markers = getMarkers(timeline)
    val segments = getRingSegments(timeline)
    return ComputedIslamicDay(
        hijriDate = hijriDate,
        timeline = timeline,
        currentPhase = currentPhase,
        nextTransitionId = nextId,
        nextTransitionAt = nextAt,
        countdownMs = countdownMs,
        ringProgress = progress,
        ringMarkers = markers,
        ringSegments = segments
    )
}
