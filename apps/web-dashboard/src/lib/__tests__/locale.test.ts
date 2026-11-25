import { describe, expect, it } from 'vitest';
import uiBn from '../../../../../packages/i18n/resources/ui-bn.json';
import uiEn from '../../../../../packages/i18n/resources/ui-en.json';
import uiFr from '../../../../../packages/i18n/resources/ui-fr.json';
import uiId from '../../../../../packages/i18n/resources/ui-id.json';
import uiRu from '../../../../../packages/i18n/resources/ui-ru.json';
import uiTr from '../../../../../packages/i18n/resources/ui-tr.json';
import uiUr from '../../../../../packages/i18n/resources/ui-ur.json';
import { resolveLanguage, translate } from '../locale';

const catalogs = { tr: uiTr, id: uiId, ur: uiUr, bn: uiBn, fr: uiFr, ru: uiRu };

describe('locale catalogs', () => {
  it('gives every language the same keys as English', () => {
    const englishKeys = Object.keys(uiEn).sort();
    for (const [code, catalog] of Object.entries(catalogs)) {
      expect(Object.keys(catalog).sort(), code).toEqual(englishKeys);
    }
  });

  it('keeps the English Fajr cue and Dhuhr solar-noon line', () => {
    expect(uiEn['cue.fajr']).toBe('If the sky is brightening, it is Fajr time.');
    expect(uiEn['technical.dhuhr.start']).toContain('solar noon (zawal)');
    expect(uiEn['notification.fajr']).toBe('Fajr. Check the horizon');
  });

  it('follows the first matching system language', () => {
    expect(resolveLanguage(['en-TR', 'ru-TR'])).toBe('en');
    expect(resolveLanguage(['tr-TR', 'en'])).toBe('tr');
    expect(resolveLanguage(['ur-PK'])).toBe('ur');
    expect(resolveLanguage(['de-DE'])).toBe('en');
  });

  it('leaves prayer names in the translated cue', () => {
    expect(translate('ru', 'cue.fajr')).toContain('Fajr');
    expect(translate('tr', 'cue.dhuhr')).toContain('Dhuhr');
  });
});
