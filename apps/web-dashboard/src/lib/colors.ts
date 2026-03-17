import type { IslamicPhaseId } from '@islamic-day-dial/core';

export const SEGMENT_COLORS: Record<IslamicPhaseId, string> = {
  maghrib_to_isha: '#ff2a6d',
  isha_to_midnight: '#b030ff',
  midnight_to_last_third: '#5050ff',
  last_third_to_fajr: '#00c8ff',
  fajr_to_sunrise: '#00e89d',
  sunrise_to_dhuhr: '#a8ff00',
  dhuhr_to_asr: '#ffd000',
  asr_to_maghrib: '#ff7a00',
};

export const SEGMENT_COLORS_ACTIVE: Record<IslamicPhaseId, string> = {
  maghrib_to_isha: '#ff5090',
  isha_to_midnight: '#cc60ff',
  midnight_to_last_third: '#7070ff',
  last_third_to_fajr: '#30e0ff',
  fajr_to_sunrise: '#30ffb8',
  sunrise_to_dhuhr: '#c8ff40',
  dhuhr_to_asr: '#ffe050',
  asr_to_maghrib: '#ff9a30',
};

export const COLORS = {
  bg: '#060612',
  surface: '#0e0e24',
  surfaceLight: '#1a1a3e',
  ringGap: '#0a0a18',
  text: '#e8e8f0',
  textSecondary: '#8888aa',
  accent: '#c69214',
  accentDim: '#8a6610',
  markerPrimary: '#e8e8f0',
  markerSecondary: '#6868a8',
  ring: '#1a1a3e',
};
