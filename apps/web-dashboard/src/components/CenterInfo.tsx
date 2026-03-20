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

export function CenterInfo({ snapshot, now, timezone }: Props) {
  const periodLabel = (() => {
    if (snapshot.currentPhase !== 'sunrise_to_dhuhr') {
      return formatCurrentPeriod(snapshot.currentPhase);
    }
    const sub = getSunriseToDhuhrSubPeriod(
      now,
      snapshot.timeline.sunrise,
      snapshot.timeline.dhuhr,
    );
    return sub === 'sunrise' ? 'Sunrise' : sub === 'duha' ? 'Duha' : 'Midday';
  })();

  const periodContent = (() => {
    if (!periodLabel) return null;
    const phase = snapshot.currentPhase;
    if (phase === 'sunrise_to_dhuhr') {
      return <span className="current-period-subsectors">{periodLabel}</span>;
    }
    if (phase === 'last_third_to_fajr') {
      return <span className="current-period-main">{periodLabel}</span>;
    }
    return <span className="current-period-main">{periodLabel}</span>;
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
