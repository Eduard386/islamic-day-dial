import {
  formatHijriDate,
  formatCurrentPeriod,
  type ComputedIslamicDay,
} from '@islamic-day-dial/core';

type Props = {
  snapshot: ComputedIslamicDay;
  now: Date;
};

export function CenterInfo({ snapshot, now }: Props) {
  const periodLabel = formatCurrentPeriod(snapshot.currentPhase);
  const localTime = now.toLocaleTimeString([], {
    hour: '2-digit',
    minute: '2-digit',
    hour12: false,
  });

  return (
    <div className="center-info">
      <div className={`current-period${!periodLabel ? ' current-period-empty' : ''}`}>
        {periodLabel || '\u00A0'}
      </div>
      <div className="hijri-date">{formatHijriDate(snapshot.hijriDate)}</div>
      <div className="local-time">{localTime}</div>
    </div>
  );
}
