import type { ComputedIslamicDay } from '@islamic-day-dial/core';
import { forwardRef } from 'react';
import {
  WEB_HIJRI_MONTH_NAMES,
  WEB_INSIGHT_AYAH_AR,
  WEB_INSIGHT_AYAH_EN,
} from '../content/desktopContent';

type Props = {
  snapshot: ComputedIslamicDay;
};

function DesktopMonthsOrnament() {
  return (
    <div className="desktop-months-ornament" aria-hidden>
      <span className="desktop-months-ornament-line" />
      <span className="desktop-months-ornament-dot" />
      <img
        className="desktop-months-ornament-rosette"
        src={`${import.meta.env.BASE_URL}hijri-ornament-divider.png`}
        alt=""
        width={28}
        height={28}
        decoding="async"
      />
      <span className="desktop-months-ornament-dot" />
      <span className="desktop-months-ornament-line" />
    </div>
  );
}

export const DesktopMonthsRail = forwardRef<HTMLElement, Props>(function DesktopMonthsRail(
  { snapshot },
  ref,
) {
  const currentMonthIndex = Math.max(0, snapshot.hijriDate.monthNumber - 1);

  return (
    <aside ref={ref} className="desktop-months-rail">
      <div className="desktop-months-stack">
        <p className="desktop-months-ayah" dir="rtl" lang="ar">
          {WEB_INSIGHT_AYAH_AR}
        </p>
        <p className="desktop-months-translation" lang="en">
          {WEB_INSIGHT_AYAH_EN}
        </p>
        <DesktopMonthsOrnament />
        <p className="desktop-months-section-label">HIJRI MONTHS</p>
        <ol className="desktop-months-list">
          {WEB_HIJRI_MONTH_NAMES.map((month, index) => (
            <li
              key={month}
              className={`desktop-month-item${index === currentMonthIndex ? ' is-active' : ''}`}
            >
              <span className="desktop-month-index">{String(index + 1).padStart(2, '0')}</span>
              <span className="desktop-month-name">{month}</span>
            </li>
          ))}
        </ol>
      </div>
    </aside>
  );
});
