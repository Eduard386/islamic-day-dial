package com.islamicdaydial.watchface

import androidx.wear.watchface.complications.data.ComplicationData
import androidx.wear.watchface.complications.data.ComplicationType
import androidx.wear.watchface.complications.datasource.ComplicationRequest
import androidx.wear.watchface.complications.datasource.SuspendingComplicationDataSourceService
import com.islamicdaydial.watchface.core.Location
import com.islamicdaydial.watchface.core.computeIslamicDaySnapshot
import com.islamicdaydial.watchface.core.formatCountdown
import com.islamicdaydial.watchface.core.getCountdownTarget
import java.util.Date
import java.util.TimeZone
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.tasks.await
import kotlinx.coroutines.withContext

/**
 * Complication data source for Islamic Day WFF watch face.
 * Provides: Hijri date (SHORT_TEXT), ring progress (RANGED_VALUE).
 */
class IslamicDayComplicationDataSourceService : SuspendingComplicationDataSourceService() {

    override suspend fun onComplicationRequest(request: ComplicationRequest): ComplicationData? {
        val location = getLastKnownLocation()
        val now = Date()
        val tz = TimeZone.getDefault().id

        return when (request.complicationType) {
            ComplicationType.SHORT_TEXT -> buildHijriShortText(location, now, tz)
            ComplicationType.RANGED_VALUE -> buildRingProgress(location, now, tz)
            else -> null
        }
    }

    private suspend fun getLastKnownLocation(): Location = withContext(Dispatchers.IO) {
        try {
            val client = com.google.android.gms.location.LocationServices.getFusedLocationProviderClient(this@IslamicDayComplicationDataSourceService)
            val loc = client.lastLocation.await()
            if (loc != null) Location(loc.latitude, loc.longitude)
            else DEFAULT_LOCATION
        } catch (_: Exception) {
            DEFAULT_LOCATION
        }
    }

    private fun buildHijriShortText(location: Location, now: java.util.Date, tz: String): ComplicationData {
        val snapshot = computeIslamicDaySnapshot(now, location, tz)
        val h = snapshot.hijriDate
        val countdownTarget = getCountdownTarget(now, snapshot.timeline)
        val countdownMs = (countdownTarget.time - now.time).coerceAtLeast(0L)
        val countdownStr = formatCountdown(countdownMs)
        return androidx.wear.watchface.complications.data.ShortTextComplicationData.Builder(
            text = androidx.wear.watchface.complications.data.PlainComplicationText.Builder(countdownStr).build(),
            contentDescription = androidx.wear.watchface.complications.data.PlainComplicationText.Builder("Countdown: $countdownStr").build()
        )
            .setTitle(androidx.wear.watchface.complications.data.PlainComplicationText.Builder("${h.day} ${h.monthNameEn}").build())
            .build()
    }

    private fun buildRingProgress(location: Location, now: java.util.Date, tz: String): ComplicationData {
        val snapshot = computeIslamicDaySnapshot(now, location, tz)
        val progressPercent = (snapshot.ringProgress * 100).toInt().coerceIn(0, 100)
        return androidx.wear.watchface.complications.data.RangedValueComplicationData.Builder(
            value = progressPercent.toFloat(),
            min = 0f,
            max = 100f,
            contentDescription = androidx.wear.watchface.complications.data.PlainComplicationText.Builder("Islamic day progress").build()
        ).setText(androidx.wear.watchface.complications.data.PlainComplicationText.Builder("$progressPercent%").build()).build()
    }

    override fun getPreviewData(type: ComplicationType): ComplicationData? {
        val now = Date()
        return when (type) {
            ComplicationType.SHORT_TEXT -> buildHijriShortText(DEFAULT_LOCATION, now, "UTC")
            ComplicationType.RANGED_VALUE -> buildRingProgress(DEFAULT_LOCATION, now, "UTC")
            else -> null
        }
    }

    companion object {
        private val DEFAULT_LOCATION = Location(21.4225, 39.8262) // Mecca
    }
}
