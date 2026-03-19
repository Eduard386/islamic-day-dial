import {
  formatHijriDateParts,
  formatCurrentPeriod,
  formatCountdown,
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

    const t = now.getTime();
    const start = snapshot.timeline.sunrise.getTime();
    const end = snapshot.timeline.dhuhr.getTime();

    // Hide DUHA at the start/end of its sector.
    const hideFirstMs = 20 * 60 * 1000;
    const hideLastMs = 5 * 60 * 1000;

    if (t < start + hideFirstMs) return '';
    if (t > end - hideLastMs) return '';
    return formatCurrentPeriod(snapshot.currentPhase);
  })();

  const periodContent = (() => {
    if (!periodLabel) return null;
    const phase = snapshot.currentPhase;
    if (phase === 'sunrise_to_dhuhr') {
      return <span className="current-period-secondary">{periodLabel}</span>;
    }
    if (phase === 'last_third_to_fajr') {
      return <span className="current-period-isha-neon">{periodLabel}</span>;
    }
    return <span className="current-period-main">{periodLabel}</span>;
  })();

  const dateParts = formatHijriDateParts(snapshot.hijriDate);
  const countdownStr = formatCountdown(snapshot.countdownMs);

  return (
    <div className="center-info">
      <div className={`current-period${!periodLabel ? ' current-period-empty' : ''}`}>
        {periodContent || '\u00A0'}
      </div>
      <div className={`hijri-date${dateParts.isEid ? ' eid-date' : ''}`}>{dateParts.dayMonth}</div>
      <div className={`hijri-year${dateParts.isEid ? ' eid-date' : ''}`}>{dateParts.year}</div>
      <div className="countdown">{countdownStr}</div>
    </div>
  );
}
