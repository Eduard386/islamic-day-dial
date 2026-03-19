import {
  formatHijriDateParts,
  formatCurrentPeriod,
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
  const dateParts = formatHijriDateParts(snapshot.hijriDate);
  const localTime = now.toLocaleTimeString([], {
    hour: '2-digit',
    minute: '2-digit',
    hour12: false,
    timeZone: timezone,
  });

  return (
    <div className="center-info">
      <div className={`current-period${!periodLabel ? ' current-period-empty' : ''}`}>
        {periodLabel || '\u00A0'}
      </div>
      <div className={`hijri-date${dateParts.isEid ? ' eid-date' : ''}`}>{dateParts.dayMonth}</div>
      <div className={`hijri-year${dateParts.isEid ? ' eid-date' : ''}`}>{dateParts.year}</div>
      <div className="local-time">{localTime}</div>
    </div>
  );
}
