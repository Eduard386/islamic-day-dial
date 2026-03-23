import {
  formatHijriDateParts,
  formatCountdown,
  getSectorDisplayName,
  type ComputedIslamicDay,
} from '@islamic-day-dial/core';

type Props = {
  snapshot: ComputedIslamicDay;
  now: Date;
  timezone: string;
};

export function CenterInfo({ snapshot, now, timezone }: Props) {
  const periodLabel = getSectorDisplayName(
    now,
    snapshot.currentPhase,
    { sunrise: snapshot.timeline.sunrise, dhuhr: snapshot.timeline.dhuhr },
  );

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
