package com.islamicdaydial.watchface

import androidx.wear.watchface.complications.data.ComplicationData
import androidx.wear.watchface.complications.data.ComplicationType
import androidx.wear.watchface.complications.datasource.ComplicationRequest
import androidx.wear.watchface.complications.datasource.SuspendingComplicationDataSourceService
import com.islamicdaydial.watchface.core.Location
import com.islamicdaydial.watchface.core.computeIslamicDaySnapshot
import com.islamicdaydial.watchface.core.formatCountdown
import com.islamicdaydial.watchface.core.getCountdownTarget
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.tasks.await
import kotlinx.coroutines.withContext
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL
import java.util.Date
import java.util.TimeZone

/** Timezone → Location fallback when IP and device location fail */
private val TIMEZONE_TO_LOCATION = mapOf(
    "Europe/Istanbul" to Location(41.0082, 28.9784),
    "Europe/London" to Location(51.5074, -0.1278),
    "Europe/Paris" to Location(48.8566, 2.3522),
    "Europe/Berlin" to Location(52.52, 13.405),
    "Europe/Kyiv" to Location(50.4501, 30.5234),
    "Asia/Riyadh" to Location(21.4225, 39.8262),
    "Asia/Dubai" to Location(25.2048, 55.2708),
    "America/New_York" to Location(40.7128, -74.006),
    "America/Los_Angeles" to Location(34.0522, -118.2437),
    "Asia/Jakarta" to Location(-6.2088, 106.8456),
    "Asia/Tokyo" to Location(35.6762, 139.6503),
    "Africa/Cairo" to Location(30.0444, 31.2357),
    "Australia/Sydney" to Location(-33.8688, 151.2093),
    "America/Sao_Paulo" to Location(-23.5505, -46.6333),
    "Asia/Kolkata" to Location(19.076, 72.8777),
    "Europe/Moscow" to Location(55.7558, 37.6173),
)

/**
 * Complication data source for Islamic Day WFF watch face.
 * Provides: Hijri date (SHORT_TEXT), ring progress (RANGED_VALUE).
 * Location: IP first, then device GPS, then timezone fallback.
 */
class IslamicDayComplicationDataSourceService : SuspendingComplicationDataSourceService() {

    override suspend fun onComplicationRequest(request: ComplicationRequest): ComplicationData? {
        val location = resolveLocation()
        val now = Date()
        val tz = TimeZone.getDefault().id

        return when (request.complicationType) {
            ComplicationType.SHORT_TEXT -> buildHijriShortText(location, now, tz)
            ComplicationType.RANGED_VALUE -> buildRingProgress(location, now, tz)
            else -> null
        }
    }

    /** IP first, then device location, then timezone fallback */
    private suspend fun resolveLocation(): Location = withContext(Dispatchers.IO) {
        fetchLocationFromIp() ?: getLastKnownLocation() ?: getTimezoneFallback()
    }

    private suspend fun fetchLocationFromIp(): Location? = withContext(Dispatchers.IO) {
        try {
            val conn = URL("https://ipapi.co/json/").openConnection() as HttpURLConnection
            conn.requestMethod = "GET"
            conn.connectTimeout = 3000
            conn.readTimeout = 3000
            val response = conn.inputStream.bufferedReader().readText()
            val json = JSONObject(response)
            val lat = json.getDouble("latitude")
            val lng = json.getDouble("longitude")
            Location(lat, lng)
        } catch (_: Exception) {
            null
        }
    }

    private suspend fun getLastKnownLocation(): Location? = withContext(Dispatchers.IO) {
        try {
            val client = com.google.android.gms.location.LocationServices.getFusedLocationProviderClient(this@IslamicDayComplicationDataSourceService)
            val loc = client.lastLocation.await()
            if (loc != null) Location(loc.latitude, loc.longitude) else null
        } catch (_: Exception) {
            null
        }
    }

    private fun getTimezoneFallback(): Location {
        val tz = TimeZone.getDefault().id
        return TIMEZONE_TO_LOCATION[tz] ?: DEFAULT_LOCATION
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
