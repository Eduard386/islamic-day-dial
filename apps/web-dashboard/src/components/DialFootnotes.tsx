import type { ComputedIslamicDay } from '@islamic-day-dial/core';
import { polarToXY } from '../lib/geometry';

type Props = {
  snapshot: ComputedIslamicDay;
  /** Must match `IslamicRing` size */
  dialSize?: number;
  /** Horizontal margin for labels + leader lines */
  sidePad?: number;
};

/** Same ring metrics as `IslamicRing`. */
function ringMetrics(dialSize: number) {
  const cx = dialSize / 2;
  const cy = dialSize / 2;
  const ringInner = dialSize * 0.25125;
  const ringStroke = dialSize * 0.081;
  const ringOuter = ringInner + ringStroke;
  return { cx, cy, ringOuter };
}

/**
 * Сноска: от внешнего края цветной полосы по радиусу наружу (риски сами только внутрь),
 * затем горизонталь к полю и вертикаль к подписи.
 */
function footnoteAnchorPoints(
  dialSize: number,
  angleDeg: number,
  markerId: string,
): { xRing: number; yRing: number; xStub: number; yStub: number } {
  const { cx, cy, ringOuter } = ringMetrics(dialSize);
  const baseStub = dialSize * 0.036;
  const stubMultiplier = markerId === 'sunrise' || markerId === 'maghrib' ? 2 : 1;
  const stubOut = baseStub * stubMultiplier;
  const onOuterRim = polarToXY(cx, cy, ringOuter, angleDeg);
  const pastRim = polarToXY(cx, cy, ringOuter + stubOut, angleDeg);
  return { xRing: onOuterRim.x, yRing: onOuterRim.y, xStub: pastRim.x, yStub: pastRim.y };
}

/** Левая колонка: дневные ориентиры по часовой логике. */
const LEFT: ReadonlyArray<{ id: string; label: string }> = [
  { id: 'sunrise', label: 'Sunrise' },
  { id: 'duha_start', label: 'Duha' },
  { id: 'duha_end', label: 'Midday' },
  { id: 'dhuhr', label: 'Dhuhr' },
  { id: 'asr', label: 'Asr' },
];

/** Правая колонка. */
const RIGHT: ReadonlyArray<{ id: string; label: string }> = [
  { id: 'maghrib', label: 'Maghrib' },
  { id: 'isha', label: 'Isha' },
  { id: 'last_third_start', label: 'Last 3rd' },
  { id: 'fajr', label: 'Fajr' },
];

const MIN_LABEL_GAP = 38;

/**
 * Разводим подписи по вертикали: вперёд с минимальным шагом, назад без сближения, снова вперёд.
 */
function spreadLabelYs(yRefs: Array<{ key: string; yRef: number }>): Map<string, number> {
  const sorted = [...yRefs].sort((a, b) => a.yRef - b.yRef);
  const keys = sorted.map((s) => s.key);
  const yRefByKey = new Map(sorted.map((s) => [s.key, s.yRef] as const));
  const n = sorted.length;
  const y: number[] = sorted.map((s) => s.yRef);

  for (let i = 1; i < n; i++) {
    y[i] = Math.max(y[i], y[i - 1] + MIN_LABEL_GAP);
  }
  for (let i = n - 2; i >= 0; i--) {
    y[i] = Math.min(y[i], y[i + 1] - MIN_LABEL_GAP);
  }
  for (let i = 0; i < n; i++) {
    y[i] = Math.max(y[i], yRefByKey.get(keys[i])!);
  }
  for (let i = 1; i < n; i++) {
    y[i] = Math.max(y[i], y[i - 1] + MIN_LABEL_GAP);
  }

  const map = new Map<string, number>();
  for (let i = 0; i < n; i++) {
    map.set(keys[i], y[i]);
  }
  return map;
}

type FootItem = {
  key: string;
  label: string;
  xRing: number;
  yRing: number;
  xStub: number;
  yStub: number;
  xMid: number;
  yLabel: number;
};

/**
 * Leader: радиально от внешнего края кольца → горизонталь к полю → вертикаль к подписи.
 */
/** Запас под разведённые подписи ниже кольца (синхронно с `--footnote-pad` в App.css) */
const FOOTNOTE_VERTICAL_PAD = 120;

export function DialFootnotes({ snapshot, dialSize = 420, sidePad = 92 }: Props) {
  const markers = snapshot.ring.markers;
  const totalW = dialSize + 2 * sidePad;
  const h = dialSize + FOOTNOTE_VERTICAL_PAD;

  const xMidLeft = sidePad - 8;
  const xMidRight = sidePad + dialSize + 8;

  const buildSide = (defs: ReadonlyArray<{ id: string; label: string }>, side: 'left' | 'right'): FootItem[] => {
    const raw = defs
      .map((def) => {
        const marker = markers.find((x) => x.id === def.id);
        if (!marker) return null;
        const a = footnoteAnchorPoints(dialSize, marker.angleDeg, def.id);
        const xRing = sidePad + a.xRing;
        const yRing = a.yRing;
        const xStub = sidePad + a.xStub;
        const yStub = a.yStub;
        const xMid = side === 'left' ? xMidLeft : xMidRight;
        return { key: def.id, label: def.label, xRing, yRing, xStub, yStub, xMid };
      })
      .filter(Boolean) as Array<{
      key: string;
      label: string;
      xRing: number;
      yRing: number;
      xStub: number;
      yStub: number;
      xMid: number;
    }>;

    const yMap = spreadLabelYs(raw.map((r) => ({ key: r.key, yRef: r.yStub })));

    return raw.map((r) => ({
      key: r.key,
      label: r.label,
      xRing: r.xRing,
      yRing: r.yRing,
      xStub: r.xStub,
      yStub: r.yStub,
      xMid: r.xMid,
      yLabel: yMap.get(r.key) ?? r.yStub,
    }));
  };

  const leftItems = buildSide(LEFT, 'left');
  const rightItems = buildSide(RIGHT, 'right');

  return (
    <>
      <svg
        className="dial-footnote-leaders"
        width={totalW}
        height={h}
        viewBox={`0 0 ${totalW} ${h}`}
        aria-hidden
      >
        {leftItems.map((it) => (
          <polyline
            key={`L-${it.key}`}
            points={`${it.xRing},${it.yRing} ${it.xStub},${it.yStub} ${it.xMid},${it.yStub} ${it.xMid},${it.yLabel}`}
            fill="none"
            className="dial-footnote-line"
          />
        ))}
        {rightItems.map((it) => (
          <polyline
            key={`R-${it.key}`}
            points={`${it.xRing},${it.yRing} ${it.xStub},${it.yStub} ${it.xMid},${it.yStub} ${it.xMid},${it.yLabel}`}
            fill="none"
            className="dial-footnote-line"
          />
        ))}
      </svg>
      {leftItems.map((it) => (
        <div
          key={`LL-${it.key}`}
          className="footnote-label footnote-label--left"
          style={{ top: it.yLabel }}
        >
          {it.label}
        </div>
      ))}
      {rightItems.map((it) => (
        <div
          key={`LR-${it.key}`}
          className="footnote-label footnote-label--right"
          style={{ top: it.yLabel }}
        >
          {it.label}
        </div>
      ))}
    </>
  );
}
