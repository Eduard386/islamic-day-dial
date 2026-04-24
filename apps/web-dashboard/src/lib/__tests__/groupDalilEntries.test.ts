import { describe, expect, it } from 'vitest';
import type { ReadingBlock } from '../../content/desktopContent';
import { groupReadingBlocksIntoDalilEntries } from '../groupDalilEntries';

describe('groupReadingBlocksIntoDalilEntries', () => {
  it('groups consecutive arabic, english, source triples and supports omitted source', () => {
    const blocks: ReadingBlock[] = [
      { kind: 'arabic', text: 'a1' },
      { kind: 'english', text: 'e1' },
      { kind: 'arabic', text: 'a2' },
      { kind: 'english', text: 'e2' },
      { kind: 'source', text: 'Sunan 1' },
    ];
    const g = groupReadingBlocksIntoDalilEntries(blocks);
    expect(g).toHaveLength(2);
    expect(g[0]).toEqual({ arabic: 'a1', english: 'e1', source: undefined });
    expect(g[1]).toEqual({ arabic: 'a2', english: 'e2', source: 'Sunan 1' });
  });
});
