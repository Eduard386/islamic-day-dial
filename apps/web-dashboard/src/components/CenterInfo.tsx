import {
  formatHijriDateParts,
  getSectorDisplayName,
  type ComputedIslamicDay,
} from '@islamic-day-dial/core';

type Props = {
  snapshot: ComputedIslamicDay;
  now: Date;
  timezone: string;
  onPeriodSelect?: () => void;
  isPeriodSelected?: boolean;
};

export function CenterInfo({ snapshot, now, timezone, onPeriodSelect, isPeriodSelected = false }: Props) {
  const periodLabel = getSectorDisplayName(
    now,
    snapshot.currentPhase,
    { duhaStart: snapshot.timeline.duhaStart, dhuhr: snapshot.timeline.dhuhr },
  );

  const periodContent = (() => {
    if (!periodLabel) return null;
    return <span className="current-period-subsectors">{periodLabel}</span>;
  })();

  const dateParts = formatHijriDateParts(snapshot.hijriDate);
  const dayMonthDisplay = dateParts.dayMonth.toUpperCase();
  const compactMonthNames = new Set(['rabi al-awwal', 'rabi al-thani', 'jumada al-ula', 'jumada al-thani']);
  const useCompactDayMonthSize = compactMonthNames.has(snapshot.hijriDate.monthNameEn.toLowerCase());
  const periodClassName = `current-period center-info-first sector-block${!periodLabel ? ' current-period-empty' : ''}${onPeriodSelect ? ' current-period-clickable' : ''}${isPeriodSelected ? ' is-selected' : ''}`;

  return (
    <div className="center-info center-info-abs">
      {onPeriodSelect ? (
        <button
          type="button"
          className={periodClassName}
          onClick={(event) => {
            event.stopPropagation();
            onPeriodSelect();
          }}
        >
          {periodContent || '\u00A0'}
        </button>
      ) : (
        <div className={periodClassName}>
          {periodContent || '\u00A0'}
        </div>
      )}

      <div className="center-date date-block hijri-date-pair">
        <div
          className={`hijri-date hijri-date-sector-style${useCompactDayMonthSize ? ' hijri-date-compact' : ''}${dateParts.isEid ? ' eid-date' : ''}`}
        >
          {dayMonthDisplay}
        </div>
        <div className={`hijri-year hijri-year-sector-style${dateParts.isEid ? ' eid-date' : ''}`}>{dateParts.year}</div>
      </div>
    </div>
  );
}
