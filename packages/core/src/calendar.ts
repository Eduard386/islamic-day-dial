import uq from '@umalqura/core';
import type { HijriDate } from './types.js';

const MONTH_NAMES_EN = [
  'Muharram',
  'Safar',
  'Rabi al-Awwal',
  'Rabi al-Thani',
  'Jumada al-Ula',
  'Jumada al-Thani',
  'Rajab',
  'Shaban',
  'Ramadan',
  'Shawwal',
  'Dhul Qadah',
  'Dhul Hijjah',
] as const;

const MONTH_NAMES_AR = [
  'محرّم',
  'صفر',
  'ربيع الأوّل',
  'ربيع الثاني',
  'جمادى الأولى',
  'جمادى الثانية',
  'رجب',
  'شعبان',
  'رمضان',
  'شوّال',
  'ذو القعدة',
  'ذو الحجّة',
] as const;

/**
 * Pure Gregorian → Hijri (Umm al-Qura) conversion.
 * Does NOT account for Maghrib transition — the caller is responsible
 * for passing the correct Gregorian date (today or tomorrow).
 */
export function getHijriDate(gregorianDate: Date): HijriDate {
  const d = uq(gregorianDate);
  return {
    day: d.hd,
    monthNumber: d.hm,
    monthNameEn: MONTH_NAMES_EN[d.hm - 1],
    monthNameAr: MONTH_NAMES_AR[d.hm - 1],
    year: d.hy,
  };
}

/**
 * Returns the Hijri date for the current Islamic day.
 * After Maghrib the Islamic date advances, so we convert tomorrow's Gregorian date.
 */
export function getIslamicDayHijriDate(now: Date, todayMaghrib: Date): HijriDate {
  if (now.getTime() >= todayMaghrib.getTime()) {
    const tomorrow = new Date(now);
    tomorrow.setDate(tomorrow.getDate() + 1);
    tomorrow.setHours(0, 0, 0, 0);
    return getHijriDate(tomorrow);
  }
  const today = new Date(now);
  today.setHours(0, 0, 0, 0);
  return getHijriDate(today);
}
