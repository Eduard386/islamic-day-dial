import { describe, expect, it } from 'vitest';
import {
  DEBUG_PRESETS,
  MY_LOCATION_INSERT_INDEX,
  PRESETS_BY_TITLE,
  PRESETS_SORTED,
} from './locationPresets';

describe('locationPresets', () => {
  it('uses the same city list in production and debug', () => {
    expect(PRESETS_SORTED.map((p) => p.title)).toEqual(DEBUG_PRESETS.map((p) => p.title));
  });

  it('keeps my location before the shared city list', () => {
    expect(MY_LOCATION_INSERT_INDEX).toBe(0);
  });

  it('builds title lookup from the shared preset list', () => {
    for (const preset of PRESETS_SORTED) {
      expect(PRESETS_BY_TITLE[preset.title]).toEqual(preset);
    }
  });
});
