import uiBn from '../../../../packages/i18n/resources/ui-bn.json';
import uiEn from '../../../../packages/i18n/resources/ui-en.json';
import uiFr from '../../../../packages/i18n/resources/ui-fr.json';
import uiId from '../../../../packages/i18n/resources/ui-id.json';
import uiRu from '../../../../packages/i18n/resources/ui-ru.json';
import uiTr from '../../../../packages/i18n/resources/ui-tr.json';
import uiUr from '../../../../packages/i18n/resources/ui-ur.json';
import scriptureBn from '../../../../packages/i18n/resources/scripture-bn.json';
import scriptureFr from '../../../../packages/i18n/resources/scripture-fr.json';
import scriptureId from '../../../../packages/i18n/resources/scripture-id.json';
import scriptureRu from '../../../../packages/i18n/resources/scripture-ru.json';
import scriptureTr from '../../../../packages/i18n/resources/scripture-tr.json';
import scriptureUr from '../../../../packages/i18n/resources/scripture-ur.json';

export const SUPPORTED_LANGUAGES = ['tr', 'id', 'ur', 'bn', 'fr', 'ru'] as const;

type Catalog = Record<string, string>;
type Passage = { text: string; notes: string; credit: string };

const UI: Record<string, Catalog> = {
  en: uiEn,
  tr: uiTr,
  id: uiId,
  ur: uiUr,
  bn: uiBn,
  fr: uiFr,
  ru: uiRu,
};

const SCRIPTURE: Record<string, Record<string, Passage>> = {
  tr: scriptureTr,
  id: scriptureId,
  ur: scriptureUr,
  bn: scriptureBn,
  fr: scriptureFr,
  ru: scriptureRu,
};

export function resolveLanguage(languages?: readonly string[]): string {
  const list = languages ?? (typeof navigator === 'undefined' ? ['en'] : navigator.languages);
  for (const tag of list) {
    const base = tag.toLowerCase().split('-')[0] ?? 'en';
    if (base === 'en') return 'en';
    if ((SUPPORTED_LANGUAGES as readonly string[]).includes(base)) return base;
  }
  return 'en';
}

export function currentLanguage(): string {
  return resolveLanguage();
}

export function translate(language: string, key: string): string {
  return UI[language]?.[key] ?? UI.en[key] ?? key;
}

export function t(key: string): string {
  return translate(currentLanguage(), key);
}

/** Turkish vakit names. Keys stay the English sector titles used by the dial logic. */
const TURKISH_SECTORS: Record<string, string> = {
  Fajr: 'İmsak',
  Shuruq: 'Güneş',
  Duha: 'Kuşluk',
  Istiwa: 'İstiva',
  Dhuhr: 'Öğle',
  Asr: 'İkindi',
  Maghrib: 'Akşam',
  Isha: 'Yatsı',
  'Last 3rd': 'Son üçte bir',
  "Jumu'ah": 'Cuma',
};

export function sectorProse(name: string, language = currentLanguage()): string {
  if (language !== 'tr') return name;
  return TURKISH_SECTORS[name] ?? name;
}

/** Ring and footnote labels are shown in capitals. Turkish İ/ı must be uppercased with a Turkish locale. */
export function sectorRing(name: string, language = currentLanguage()): string {
  const prose = sectorProse(name, language);
  return prose.toLocaleUpperCase(language === 'tr' ? 'tr' : 'en');
}

export function textWithPublished(fallback: string, id: string): string {
  const language = currentLanguage();
  if (language === 'en') return fallback;
  const passage = SCRIPTURE[language]?.[id];
  if (!passage?.text) return fallback;
  return [passage.text, passage.notes].filter((part) => part.length > 0).join('\n\n');
}
