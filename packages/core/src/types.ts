export type Location = {
  latitude: number;
  longitude: number;
};

export type UserContext = {
  now: Date;
  location: Location;
  timezone: string;
};

export type HijriDate = {
  day: number;
  monthNumber: number;
  monthNameEn: string;
  monthNameAr?: string;
  year: number;
};

export type PrayerTimesData = {
  fajr: Date;
  sunrise: Date;
  dhuhr: Date;
  asr: Date;
  maghrib: Date;
  isha: Date;
};

export type DerivedMarkers = {
  lastThirdStart: Date;
};

export type IslamicPhaseId =
  | 'maghrib_to_isha'
  | 'isha_to_last_third'
  | 'last_third_to_fajr'
  | 'fajr_to_sunrise'
  | 'sunrise_to_dhuhr'
  | 'dhuhr_to_asr'
  | 'asr_to_maghrib';

export type RingMarkerKind = 'primary' | 'secondary';

export type RingMarkerId =
  | 'maghrib'
  | 'isha'
  | 'last_third_start'
  | 'fajr'
  | 'sunrise'
  | 'duha_start'
  | 'duha_end'
  | 'dhuhr'
  | 'asr';

export type RingMarker = {
  id: RingMarkerId;
  timestamp: Date;
  angleDeg: number;
  kind: RingMarkerKind;
};

export type RingSegment = {
  id: IslamicPhaseId;
  start: Date;
  end: Date;
  startAngleDeg: number;
  endAngleDeg: number;
};

/**
 * Ordered sequence of all boundary timestamps within one Islamic day.
 * Starts at lastMaghrib (top of the ring) and ends at nextMaghrib.
 */
export type ComputedTimeline = {
  lastMaghrib: Date;
  isha: Date;
  lastThirdStart: Date;
  fajr: Date;
  sunrise: Date;
  duhaStart: Date;
  duhaEnd: Date;
  dhuhr: Date;
  asr: Date;
  nextMaghrib: Date;
};

export type ComputedIslamicDay = {
  hijriDate: HijriDate;
  prayerTimes: PrayerTimesData;
  derivedMarkers: DerivedMarkers;
  timeline: ComputedTimeline;
  currentPhase: IslamicPhaseId;
  nextTransition: {
    id: string;
    at: Date;
  };
  countdownMs: number;
  ring: {
    progress: number;
    markers: RingMarker[];
    segments: RingSegment[];
  };
};

export const PHASE_ORDER: readonly IslamicPhaseId[] = [
  'maghrib_to_isha',
  'isha_to_last_third',
  'last_third_to_fajr',
  'fajr_to_sunrise',
  'sunrise_to_dhuhr',
  'dhuhr_to_asr',
  'asr_to_maghrib',
] as const;

export type TimelineKey = keyof ComputedTimeline;

/**
 * Maps each phase to its [startKey, endKey] in ComputedTimeline.
 */
export const PHASE_BOUNDARIES: ReadonlyArray<{
  id: IslamicPhaseId;
  startKey: TimelineKey;
  endKey: TimelineKey;
}> = [
  { id: 'maghrib_to_isha', startKey: 'lastMaghrib', endKey: 'isha' },
  { id: 'isha_to_last_third', startKey: 'isha', endKey: 'lastThirdStart' },
  { id: 'last_third_to_fajr', startKey: 'lastThirdStart', endKey: 'fajr' },
  { id: 'fajr_to_sunrise', startKey: 'fajr', endKey: 'sunrise' },
  { id: 'sunrise_to_dhuhr', startKey: 'sunrise', endKey: 'dhuhr' },
  { id: 'dhuhr_to_asr', startKey: 'dhuhr', endKey: 'asr' },
  { id: 'asr_to_maghrib', startKey: 'asr', endKey: 'nextMaghrib' },
];
