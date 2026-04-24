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

function eidHeadingFromHijri(hijri: { day: number; monthNumber: number }): string | null {
  if (hijri.monthNumber === 10 && hijri.day === 1) return 'EID AL-FITR';
  if (hijri.monthNumber === 12 && hijri.day === 10) return 'EID AL-ADHA';
  return null;
}

/** On Eid, sector title in the hole is hidden during this window (holiday uses the date line). */
const EID_SUPPRESSED_SECTOR_LABELS = new Set(['Duha', 'Midday', 'Dhuhr', "Jumu'ah"]);

export function CenterInfo({ snapshot, now, timezone, onPeriodSelect, isPeriodSelected = false }: Props) {
  const periodLabel = getSectorDisplayName(
    now,
    snapshot.currentPhase,
    { duhaStart: snapshot.timeline.duhaStart, dhuhr: snapshot.timeline.dhuhr },
  );

  const dateParts = formatHijriDateParts(snapshot.hijriDate);
  const eidHeading = dateParts.isEid ? eidHeadingFromHijri(snapshot.hijriDate) : null;

  const suppressSectorOnEid = Boolean(eidHeading && periodLabel && EID_SUPPRESSED_SECTOR_LABELS.has(periodLabel));
  const showSectorRow = !suppressSectorOnEid;

  const periodContent = showSectorRow && periodLabel ? (
    <span className="current-period-subsectors">{periodLabel}</span>
  ) : null;

  const dayMonthDisplay = dateParts.dayMonth.toUpperCase();
  const compactMonthNames = new Set(['rabi al-awwal', 'rabi al-thani', 'jumada al-ula', 'jumada al-thani']);
  const useCompactDayMonthSize = compactMonthNames.has(snapshot.hijriDate.monthNameEn.toLowerCase());

  const jumuahSectorClass = showSectorRow && periodLabel === "Jumu'ah" ? ' current-period--jumuah' : '';
  const periodClassName = `current-period center-info-first sector-block${jumuahSectorClass}${!periodContent ? ' current-period-empty' : ''}${onPeriodSelect && showSectorRow ? ' current-period-clickable' : ''}${isPeriodSelected && showSectorRow ? ' is-selected' : ''}`;

  const dateFirstLineClass = eidHeading
    ? 'hijri-date hijri-date-sector-style hijri-eid-title eid-date'
    : `hijri-date hijri-date-sector-style${useCompactDayMonthSize ? ' hijri-date-compact' : ''}`;

  const dateBlockClass = `center-date date-block hijri-date-pair${onPeriodSelect && suppressSectorOnEid ? ' center-date-clickable' : ''}${isPeriodSelected && suppressSectorOnEid ? ' is-selected' : ''}`;

  const dateInner = (
    <>
      <div className={dateFirstLineClass}>{eidHeading ?? dayMonthDisplay}</div>
      <div className={`hijri-year hijri-year-sector-style${eidHeading ? ' eid-date' : ''}`}>{dateParts.year}</div>
    </>
  );

  return (
    <div className="center-info center-info-abs">
      {showSectorRow &&
        (onPeriodSelect ? (
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
        ))}

      {!showSectorRow && eidHeading && (
        <div
          className="current-period center-info-first sector-block current-period-empty center-info-eid-sector-spacer"
          aria-hidden
        >
          {'\u00A0'}
        </div>
      )}

      {suppressSectorOnEid && onPeriodSelect ? (
        <button
          type="button"
          className={dateBlockClass}
          onClick={(event) => {
            event.stopPropagation();
            onPeriodSelect();
          }}
        >
          {dateInner}
        </button>
      ) : (
        <div className={dateBlockClass}>{dateInner}</div>
      )}
    </div>
  );
}
