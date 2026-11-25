import { WEB_DIAL_FOOTER_AYAH_4_103_AR, WEB_DIAL_FOOTER_AYAH_4_103_EN } from '../content/desktopContent';
import { currentLanguage, textWithPublished } from '../lib/locale';

/** Quran 4:103 — above the dial; ornament + OBSERVE sit below the ring. */
export function DialBelowRingAyah() {
  return (
    <aside className="dial-below-ring-ayah" aria-label="Quran 4:103">
      <p className="dial-below-ring-ayah__arabic" dir="rtl" lang="ar">
        {WEB_DIAL_FOOTER_AYAH_4_103_AR}
      </p>
      <p className="dial-below-ring-ayah__english" dir="auto" lang={currentLanguage()}>
        {textWithPublished(WEB_DIAL_FOOTER_AYAH_4_103_EN, 'quran.4.103')}
      </p>
    </aside>
  );
}
