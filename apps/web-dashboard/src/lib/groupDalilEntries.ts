import type { ReadingBlock } from '../content/desktopContent';

export type DalilReadingEntry = {
  arabic: string;
  english: string;
  source?: string;
};

export const DALIL_SECTION_LABEL_AR = [
  'الدَّلِيلُ الأَوَّلُ',
  'الدَّلِيلُ الثَّانِي',
  'الدَّلِيلُ الثَّالِثُ',
  'الدَّلِيلُ الرَّابِعُ',
  'الدَّلِيلُ الْخَامِسُ',
  'الدَّلِيلُ السَّادِسُ',
  'الدَّلِيلُ السَّابِعُ',
  'الدَّلِيلُ الثَّامِنُ',
] as const;

export function dalilSectionLabelAr(index: number): string {
  const i = Math.max(0, Math.min(index, DALIL_SECTION_LABEL_AR.length - 1));
  return DALIL_SECTION_LABEL_AR[i];
}

export function formatDalilSourceLine(source: string): string {
  const t = source.trim();
  if (t.startsWith('—') || t.startsWith('–') || t.startsWith('-')) return t;
  return `— ${t}`;
}

/** Groups flat reading blocks into dalil entries without changing source order or text. */
export function groupReadingBlocksIntoDalilEntries(blocks: ReadingBlock[]): DalilReadingEntry[] {
  const entries: DalilReadingEntry[] = [];
  let i = 0;
  while (i < blocks.length) {
    const b = blocks[i];
    if (b.kind !== 'arabic') {
      i += 1;
      continue;
    }
    const arabic = b.text;
    i += 1;
    let english = '';
    let source: string | undefined;
    if (i < blocks.length && blocks[i].kind === 'english') {
      english = blocks[i].text;
      i += 1;
    }
    if (i < blocks.length && blocks[i].kind === 'source') {
      source = blocks[i].text;
      i += 1;
    }
    entries.push({ arabic, english, source });
  }
  return entries;
}
