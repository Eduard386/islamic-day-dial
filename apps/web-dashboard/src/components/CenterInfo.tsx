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
  const periodLabel = formatCurrentPeriod(snapshot.currentPhase);
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
