import {
  formatHijriDateParts,
  formatCurrentPeriod,
  formatCountdown,
  getSunriseToDhuhrSubPeriod,
  type ComputedIslamicDay,
} from '@islamic-day-dial/core';

type Props = {
  snapshot: ComputedIslamicDay;
  now: Date;
  timezone: string;
};

/** Пятница: DUHA / MIDDAY / DHUHR → одно имя латиницей */
const JUMU_LABEL = "Jumu'ah";

export function CenterInfo({ snapshot, now, timezone }: Props) {
  const isFriday = now.getDay() === 5;

  const periodLabel = (() => {
    if (snapshot.currentPhase === 'dhuhr_to_asr' && isFriday) {
      return JUMU_LABEL;
    }
    if (snapshot.currentPhase !== 'sunrise_to_dhuhr') {
      return formatCurrentPeriod(snapshot.currentPhase);
    }
    const sub = getSunriseToDhuhrSubPeriod(
      now,
      snapshot.timeline.sunrise,
      snapshot.timeline.dhuhr,
    );
    if (sub === 'sunrise') return 'Sunrise';
    if (isFriday && (sub === 'duha' || sub === 'midday')) return JUMU_LABEL;
    return sub === 'duha' ? 'Duha' : 'Midday';
  })();

  const periodContent = (() => {
    if (!periodLabel) return null;
    return <span className="current-period-subsectors">{periodLabel}</span>;
  })();

  const dateParts = formatHijriDateParts(snapshot.hijriDate);
  const countdownStr = formatCountdown(snapshot.countdownMs);
  const dayMonthDisplay = dateParts.dayMonth.toUpperCase();
  const compactMonthNames = new Set(['rabi al-awwal', 'rabi al-thani', 'jumada al-ula', 'jumada al-thani']);
  const useCompactDayMonthSize = compactMonthNames.has(snapshot.hijriDate.monthNameEn.toLowerCase());

  return (
    <div className="center-info center-info-abs">
      <div className={`current-period center-info-first sector-block ${!periodLabel ? 'current-period-empty' : ''}`}>
        {periodContent || '\u00A0'}
      </div>

      <div className="center-date date-block">
        <div
          className={`hijri-date hijri-date-sector-style${useCompactDayMonthSize ? ' hijri-date-compact' : ''}${dateParts.isEid ? ' eid-date' : ''}`}
        >
          {dayMonthDisplay}
        </div>
        <div className={`hijri-year hijri-year-sector-style${dateParts.isEid ? ' eid-date' : ''}`}>{dateParts.year}</div>
      </div>

      <div className="countdown countdown-block">{countdownStr}</div>
    </div>
  );
}
