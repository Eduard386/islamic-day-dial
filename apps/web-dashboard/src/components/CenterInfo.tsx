import {
  formatHijriDate,
  formatCountdown,
  formatCurrentPeriod,
  formatTransition,
  type ComputedIslamicDay,
} from '@islamic-day-dial/core';

type Props = {
  snapshot: ComputedIslamicDay;
  now: Date;
};

export function CenterInfo({ snapshot, now }: Props) {
  const localTime = now.toLocaleTimeString([], {
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit',
    hour12: false,
  });

  return (
    <div className="center-info">
      <div className="current-period">{formatCurrentPeriod(snapshot.currentPhase)}</div>
      <div className="hijri-date">{formatHijriDate(snapshot.hijriDate)}</div>
      <div className="countdown">
        <span className="countdown-label">
          {formatTransition(snapshot.nextTransition.id)} in
        </span>
        <span className="countdown-value">{formatCountdown(snapshot.countdownMs)}</span>
      </div>
      <div className="local-time">{localTime}</div>
    </div>
  );
}
