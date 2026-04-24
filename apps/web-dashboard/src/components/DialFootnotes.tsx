import { formatHijriDateParts, type ComputedIslamicDay } from '@islamic-day-dial/core';
import { polarToXY } from '../lib/geometry';
import { getDialFootnoteAnchorAngleDeg, getExplodedRingArcSpecs, type ExplodedArcId } from '../lib/explodedRing';

type Props = {
  snapshot: ComputedIslamicDay;
  dialSize?: number;
  sidePad?: number;
  activeLabelId?: string | null;
  onSelect?: (id: string) => void;
};

type FootnoteDef = {
  id: string;
  label: string;
  arcId: ExplodedArcId;
  side: 'left' | 'right';
  rowYRatio: number;
};

type FootnoteItem = {
  key: string;
  label: string;
  points: Array<{ x: number; y: number }>;
  labelLeft: number;
  labelWidth: number;
  labelY: number;
  side: 'left' | 'right';
};

const FOOTNOTE_DEFS: ReadonlyArray<FootnoteDef> = [
  { id: 'asr', label: 'Asr', arcId: 'asr', side: 'left', rowYRatio: 0.14 },
  { id: 'dhuhr', label: 'Dhuhr', arcId: 'dhuhr', side: 'left', rowYRatio: 0.28 },
  { id: 'duha_end', label: 'Midday', arcId: 'midday', side: 'left', rowYRatio: 0.73 },
  { id: 'duha_start', label: 'Duha', arcId: 'duha', side: 'left', rowYRatio: 0.85 },
  { id: 'sunrise', label: 'Sunrise', arcId: 'sunrise', side: 'left', rowYRatio: 0.96 },
  { id: 'maghrib', label: 'Maghrib', arcId: 'maghrib', side: 'right', rowYRatio: 0.14 },
  { id: 'isha', label: 'Isha', arcId: 'isha', side: 'right', rowYRatio: 0.28 },
  { id: 'last_third_start', label: 'Last 3rd', arcId: 'lastThird', side: 'right', rowYRatio: 0.85 },
  { id: 'fajr', label: 'Fajr', arcId: 'fajr', side: 'right', rowYRatio: 0.96 },
];

function ringMetrics(dialSize: number) {
  const cx = dialSize / 2;
  const cy = dialSize / 2;
  const ringInner = dialSize * 0.25125;
  const ringStroke = dialSize * 0.081;
  const ringOuter = ringInner + ringStroke;
  const ringCenter = ringInner + ringStroke / 2;
  return { cx, cy, ringOuter, ringCenter };
}

function footnoteAnchorPoints(
  dialSize: number,
  angleDeg: number,
): { xCenter: number; yCenter: number; xLead: number; yLead: number } {
  const { cx, cy, ringCenter, ringOuter } = ringMetrics(dialSize);
  const leadOut = Math.max(dialSize * 0.042, ringOuter - ringCenter + 8);
  const centerPoint = polarToXY(cx, cy, ringCenter, angleDeg);
  const leadPoint = polarToXY(cx, cy, ringCenter + leadOut, angleDeg);
  return { xCenter: centerPoint.x, yCenter: centerPoint.y, xLead: leadPoint.x, yLead: leadPoint.y };
}

export function DialFootnotes({ snapshot, dialSize = 420, sidePad = 92, activeLabelId = null, onSelect }: Props) {
  const totalW = dialSize + sidePad * 2;
  const totalH = dialSize;
  const labelFont = Math.max(8.8, dialSize * (9.7 / 420));
  const labelHeight = Math.max(28, labelFont * 2.15);
  const labelInset = 12;
  const columnWidth = Math.max(118, sidePad - 24);
  const labelConnectorGap = 10;
  const specs = getExplodedRingArcSpecs(snapshot);
  const specById = new Map(specs.map((spec) => [spec.id, spec]));
  const isEidDay = formatHijriDateParts(snapshot.hijriDate).isEid;
  const leftColumnLeft = labelInset;
  const rightColumnLeft = totalW - labelInset - columnWidth;

  const items: FootnoteItem[] = FOOTNOTE_DEFS.flatMap((def) => {
    const spec = specById.get(def.arcId);
    if (!spec) return [];

    const angle = getDialFootnoteAnchorAngleDeg(spec, isEidDay);
    const anchor = footnoteAnchorPoints(dialSize, angle);
    const xStart = sidePad + anchor.xCenter;
    const yStart = anchor.yCenter;
    const xLead = sidePad + anchor.xLead;
    const yLead = anchor.yLead;
    const labelY = dialSize * def.rowYRatio;
    const labelLeft = def.side === 'left' ? leftColumnLeft : rightColumnLeft;
    const labelEdgeX =
      def.side === 'left'
        ? leftColumnLeft + columnWidth + labelConnectorGap
        : rightColumnLeft - labelConnectorGap;

    return [{
      key: def.id,
      label: def.label,
      points: [
        { x: xStart, y: yStart },
        { x: xLead, y: yLead },
        { x: labelEdgeX, y: labelY },
      ],
      labelLeft,
      labelWidth: columnWidth,
      labelY,
      side: def.side,
    }];
  });

  return (
    <>
      <svg
        className="dial-footnote-leaders"
        width={totalW}
        height={totalH}
        viewBox={`0 0 ${totalW} ${totalH}`}
        aria-hidden
      >
        {items.map((it) => (
          <polyline
            key={it.key}
            points={it.points.map((point) => `${point.x},${point.y}`).join(' ')}
            fill="none"
            className={`dial-footnote-line${activeLabelId === it.key ? ' is-active' : ''}`}
          />
        ))}
      </svg>
      {items.map((it) => (
        <div
          key={`label-${it.key}`}
          className={`footnote-label footnote-label--${it.side}${activeLabelId === it.key ? ' is-active' : ''}${onSelect ? ' is-clickable' : ''}`}
          style={{
            top: it.labelY,
            left: it.labelLeft,
            width: it.labelWidth,
            height: labelHeight,
          }}
        >
          {onSelect ? (
            <button type="button" className="footnote-label-button" onClick={() => onSelect(it.key)}>
              {it.label}
            </button>
          ) : (
            it.label
          )}
        </div>
      ))}
    </>
  );
}
