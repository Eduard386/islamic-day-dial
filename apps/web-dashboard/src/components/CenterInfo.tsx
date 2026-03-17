import {
  formatHijriDate,
  formatCurrentPeriod,
  type ComputedIslamicDay,
} from '@islamic-day-dial/core';

type Props = {
  snapshot: ComputedIslamicDay;
};

export function CenterInfo({ snapshot }: Props) {
  const periodLabel = formatCurrentPeriod(snapshot.currentPhase);

  return (
    <div className="center-info">
      {periodLabel && <div className="current-period">{periodLabel}</div>}
      <div className="hijri-date">{formatHijriDate(snapshot.hijriDate)}</div>
    </div>
  );
}
