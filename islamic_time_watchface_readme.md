# Islamic Time Watchface / Prayer Ring — Product & Technical README

## 1. Что это за проект

Проект — это визуальный исламский циферблат / prayer ring, который показывает не абстрактные гражданские сутки, а **исламские сутки**, начинающиеся с **локального Maghrib**.

Основная идея продукта:

- **дата по Хиджре** считается по системе **Umm al-Qura**;
- **момент переключения суток на экране** — **локальный Maghrib**;
- **времена намаза** считаются по **геолокации пользователя**;
- верхняя точка кольца — **Maghrib**;
- внутри кольца показываются:
  - дата по Хиджре,
  - текущая фаза суток,
  - таймер до следующего намаза,
  - опционально мелким текстом local time.

Это не “обычные часы” и не календарь в западной логике. Это прибор переходов исламских суток.

---

## 2. Цели проекта

### 2.1. Основная цель

Сделать продукт, который одним взглядом показывает:

- какой сейчас день по Хиджре;
- в какой фазе исламских суток находится пользователь;
- когда следующий переход / следующий намаз;
- сколько времени осталось до него.

### 2.2. Формы продукта

Проект должен поддерживать несколько “поверхностей”:

1. **Wear OS watch face** — главный продукт и первый коммерческий релиз.
2. **Web dashboard / web visualizer** — отладка, демонстрация, companion.
3. **Apple Watch app** — отдельный второй клиент в будущем.
4. Позже:
   - Apple complication,
   - Wear tile,
   - возможно phone companion.

### 2.3. Чего не делать на старте

Не делать сразу:

- backend;
- аккаунты;
- синхронизацию между устройствами;
- сложную систему настроек;
- много экранов;
- iPhone/Android phone app как основной продукт;
- одновременную разработку Apple и Wear OS;
- попытку построить всё вокруг веба с надеждой потом “перенести UI”.

---

## 3. Ключевые продуктовые решения

### 3.1. Дата по Хиджре

- Использовать **Umm al-Qura**.
- Не использовать tabular Islamic.
- Не использовать local moon sighting logic в первой версии.

### 3.2. Момент смены суток

- Переключение отображаемых исламских суток происходит в **локальный Maghrib**.
- Это важнее для UX, чем гражданская полночь.

### 3.3. Prayer times

- Считать по **геолокации** пользователя.
- На старте — без отдельного backend.
- На старте — локальные вычисления.

### 3.4. Верхняя точка кольца

- Верхняя точка (условные “12 часов”) — **Maghrib**.
- Это начало исламских суток в продуктовой модели.

### 3.5. Islamic midnight

- Показывать как **дополнительную справочную точку**.
- Это не главный маркер, а secondary reference marker.
- Основание: хадис о том, что время `Isha` длится до половины ночи.

### 3.6. Last third of the night

- Выделять как **дополнительную ночную дугу**.
- Это интервал, а не просто точка.
- Начало последней трети ночи вычислять как:
  - `lastThirdStart = fajr - (nightDuration / 3)`
  - где `nightDuration = fajr - maghrib` с переходом через гражданскую полночь.

### 3.7. Fajr Safety Cutoff

- В первой версии **не делать**.
- Основная граница Фаджра — до Sunrise.
- UX safety buffer можно добавить позже.

---

## 4. Основной UI и информационная модель

### 4.1. Что должен показывать основной экран

Обязательные элементы:

- кольцо исламских суток;
- сектора суток;
- ключевые маркеры на кольце;
- текущая дата по Хиджре;
- countdown до следующего намаза / следующего перехода;
- текущая фаза суток;
- мелким текстом local time.

### 4.2. Что не обязательно показывать на старте

- григорианская дата;
- большие цифровые часы `HH:MM:SS`;
- длинные подписи на окружности;
- список всех prayer times на основном часовом экране;
- сложные настройки.

### 4.3. Маркеры кольца

#### Основные маркеры (primary)

- Maghrib
- Isha
- Fajr
- Sunrise
- Dhuhr
- Asr

#### Дополнительные маркеры (secondary)

- Islamic Midnight
- Last Third Start

### 4.4. Последовательность маркеров по кольцу

Порядок по часовой стрелке, начиная сверху:

1. Maghrib
2. Isha
3. Islamic Midnight
4. Last Third Start
5. Fajr
6. Sunrise
7. Dhuhr
8. Asr
9. снова Maghrib

### 4.5. Основные фазы суток

Базовое деление фаз:

- Maghrib → Isha
- Isha → Islamic Midnight
- Islamic Midnight → Last Third Start
- Last Third Start → Fajr
- Fajr → Sunrise
- Sunrise → Dhuhr
- Dhuhr → Asr
- Asr → Maghrib

### 4.6. Содержимое центра кольца

Минимальный вариант:

- `14 Ramadan 1447`
- `До Maghrib 01:12:34`
- `Сейчас: Asr`
- `16:42 local`

Альтернативный вариант:

- дата по Хиджре;
- следующая граница;
- countdown;
- текущая фаза;
- local time мелко.

### 4.7. Принципы визуального веса

- Maghrib — самый сильный якорный маркер;
- Fajr / Sunrise — высоко значимые;
- Isha / Dhuhr / Asr — primary markers;
- Islamic Midnight — secondary marker;
- Last Third — secondary highlighted arc;
- текущий момент — отдельная движущаяся точка / indicator.

---

## 5. Общая архитектура

Архитектура должна быть многослойной и платформенно-нейтральной.

### 5.1. Основные слои

#### Layer A — Core / Domain

Ничего не знает про React, DOM, Android UI, SwiftUI, watch face layout.

Отвечает за:

- Hijri date;
- prayer times;
- вычисление границ исламских суток;
- вычисление фаз;
- вычисление countdown;
- вычисление маркеров кольца;
- вычисление дуг и прогресса кольца.

#### Layer B — Platform Adapters

Достаёт от платформы:

- текущее время;
- геолокацию;
- timezone;
- локальные настройки.

Не содержит доменной логики.

#### Layer C — Presentation / UI

Рендерит:

- кольцо;
- метки;
- дуги;
- дату;
- countdown;
- подписи.

Реализуется отдельно для:

- Web dashboard,
- Wear OS watch face,
- Apple Watch app.

---

## 6. Технологический стек

### 6.1. Базовый язык

Основной язык проекта на старте: **TypeScript**.

Причины:

- быстрый запуск;
- легко сделать web visualizer;
- удобно писать unit tests;
- можно использовать как reference implementation;
- легко поддерживать monorepo.

### 6.2. Почему не Rust на старте

Rust можно рассматривать только в будущем, если понадобится общий сверхнадёжный portable core.

На старте Rust **не нужен**, потому что:

- повышает сложность;
- замедляет MVP;
- не даёт ощутимой пользы на текущем этапе.

### 6.3. Языки по платформам

#### Core
- TypeScript

#### Web dashboard
- TypeScript
- React
- Vite
- SVG

#### Wear OS
- отдельная реализация watch face под платформу
- ориентироваться на **Watch Face Format (WFF)**
- при необходимости использовать Android tooling для preview/build

#### Apple Watch
- Swift
- SwiftUI
- WidgetKit для complication / widgets later

---

## 7. Monorepo-структура

Рекомендуемая структура:

```txt
islamic-time/
  apps/
    web-dashboard/
  packages/
    core/
    design/
    test-fixtures/
  services/
    api/
  docs/
  .github/
    workflows/
```

### 7.1. `packages/core`

Содержит доменную логику.

Модули:

- `calendar/`
- `prayer-times/`
- `day-bounds/`
- `night-markers/`
- `phases/`
- `countdown/`
- `ring/`
- `formatting/`
- `types/`

### 7.2. `packages/design`

Содержит платформенно-независимые design decisions:

- токены толщин;
- правила визуального веса;
- словари подписей;
- типы маркеров;
- цвета/стили;
- icon semantics.

### 7.3. `packages/test-fixtures`

Содержит предопределённые test scenarios:

- Istanbul summer
- Istanbul winter
- Mecca Ramadan
- edge cases around Maghrib
- edge cases around Fajr
- DST cases
- high-latitude future cases if needed

### 7.4. `apps/web-dashboard`

Веб-визуализатор и debug panel.

### 7.5. `services/api`

На старте может быть пустым.

Не нужен до тех пор, пока не появятся:

- синхронизация;
- аккаунты;
- subscriptions backend;
- analytics;
- shared settings.

---

## 8. Domain model: какие сущности нужны

### 8.1. Входные данные

```ts
export type UserContext = {
  now: Date;
  location: {
    latitude: number;
    longitude: number;
  };
  timezone: string;
};
```

### 8.2. Hijri date

```ts
export type HijriDate = {
  day: number;
  monthNumber: number;
  monthNameEn: string;
  monthNameAr?: string;
  year: number;
};
```

### 8.3. Prayer times

```ts
export type PrayerTimes = {
  maghrib: Date;
  isha: Date;
  fajr: Date;
  sunrise: Date;
  dhuhr: Date;
  asr: Date;
};
```

### 8.4. Derived markers

```ts
export type DerivedMarkers = {
  lastMaghrib: Date;
  nextMaghrib: Date;
  islamicMidnight: Date;
  lastThirdStart: Date;
};
```

### 8.5. Phase identifiers

```ts
export type IslamicPhaseId =
  | 'maghrib_to_isha'
  | 'isha_to_midnight'
  | 'midnight_to_last_third'
  | 'last_third_to_fajr'
  | 'fajr_to_sunrise'
  | 'sunrise_to_dhuhr'
  | 'dhuhr_to_asr'
  | 'asr_to_maghrib';
```

### 8.6. Ring marker

```ts
export type RingMarker = {
  id:
    | 'maghrib'
    | 'isha'
    | 'islamic_midnight'
    | 'last_third_start'
    | 'fajr'
    | 'sunrise'
    | 'dhuhr'
    | 'asr';
  timestamp: Date;
  angleDeg: number;
  kind: 'primary' | 'secondary';
};
```

### 8.7. Ring segment

```ts
export type RingSegment = {
  id: IslamicPhaseId;
  start: Date;
  end: Date;
  startAngleDeg: number;
  endAngleDeg: number;
};
```

### 8.8. Финальный computed snapshot

```ts
export type ComputedIslamicDay = {
  hijriDate: HijriDate;
  prayerTimes: PrayerTimes;
  markers: DerivedMarkers;
  currentPhase: IslamicPhaseId;
  nextTransition: {
    id: string;
    at: Date;
  };
  countdownMs: number;
  ring: {
    progress: number;
    markers: RingMarker[];
    segments: RingSegment[];
  };
};
```

---

## 9. Core API: какие функции должны быть

### 9.1. Calendar

```ts
getHijriDateUmmAlQura(now: Date, timezone: string): HijriDate
```

Задача:
- вернуть дату по Хиджре в системе Umm al-Qura.

### 9.2. Prayer times

```ts
getPrayerTimes(now: Date, location: Location, timezone: string): PrayerTimes
```

Задача:
- вычислить локальные prayer times для нужной даты.

Важно:
- логика должна корректно учитывать переходы вокруг Maghrib;
- возможно понадобится получение prayer times для соседних гражданских дат.

### 9.3. Bounds of the Islamic day

```ts
getIslamicDayBounds(now: Date, prayerTimesToday: PrayerTimes, prayerTimesYesterday?: PrayerTimes, prayerTimesTomorrow?: PrayerTimes): {
  lastMaghrib: Date;
  nextMaghrib: Date;
}
```

Задача:
- определить исламские сутки как интервал `lastMaghrib → nextMaghrib`.

### 9.4. Islamic midnight

```ts
getIslamicMidnight(lastMaghrib: Date, fajr: Date): Date
```

Формула:
- midpoint между `lastMaghrib` и `fajr`.

### 9.5. Last third of the night

```ts
getLastThirdStart(lastMaghrib: Date, fajr: Date): Date
```

Формула:
- `fajr - ((fajr - lastMaghrib) / 3)`

### 9.6. Current phase

```ts
getCurrentPhase(now: Date, timeline: ComputedTimeline): IslamicPhaseId
```

### 9.7. Next transition

```ts
getNextTransition(now: Date, timeline: ComputedTimeline): {
  id: string;
  at: Date;
}
```

### 9.8. Countdown

```ts
getCountdown(now: Date, nextTransitionAt: Date): number
```

### 9.9. Ring progress

```ts
getIslamicDayProgress(now: Date, lastMaghrib: Date, nextMaghrib: Date): number
```

Формула:
- `(now - lastMaghrib) / (nextMaghrib - lastMaghrib)`

### 9.10. Ring markers

```ts
getMarkers(timeline: ComputedTimeline): RingMarker[]
```

### 9.11. Ring segments

```ts
getRingSegments(timeline: ComputedTimeline): RingSegment[]
```

### 9.12. Full snapshot

```ts
computeIslamicDaySnapshot(input: UserContext): ComputedIslamicDay
```

Это основной orchestration entrypoint.

---

## 10. Откуда брать исходные данные

### 10.1. Что приходит от платформы

Платформа должна давать:

- текущее время;
- timezone;
- геолокацию.

### 10.2. Что считается локально

В core локально считаются:

- prayer times;
- Hijri date;
- phase model;
- countdown;
- дуги кольца;
- углы меток.

### 10.3. Что не нужно тянуть с backend на старте

Не нужно тянуть с сервера:

- prayer times;
- дату по Хиджре;
- phases;
- ring geometry.

Это всё лучше считать локально на первом этапе.

---

## 11. Backend: нужен ли он

### 11.1. На старте

**Не нужен.**

Причины:

- лишняя инфраструктура;
- лишняя стоимость;
- лишняя точка отказа;
- часы и оффлайн-сценарии выигрывают от локальных расчётов.

### 11.2. Когда backend может понадобиться

Добавлять backend только если появятся реальные потребности:

- аккаунты;
- синхронизация между устройствами;
- cloud settings;
- покупки и entitlement sync;
- аналитика;
- административная панель;
- поддержка подписок.

### 11.3. Предлагаемая роль backend в будущем

Если backend появится, он должен быть **тонким**:

- хранение user settings;
- entitlement management;
- analytics ingestion;
- optional consistency API;
- support tooling.

Он не должен ломать оффлайн-работу базового watch experience.

---

## 12. Web dashboard / web visualizer

### 12.1. Зачем нужен веб

Web нужен обязательно, но не как главный продукт на первом этапе.

Его роли:

1. **Debug surface**
2. **Visual prototype**
3. **Demo / showcase**
4. **Companion в будущем**

### 12.2. Что должно быть в web dashboard

- рендер кольца через SVG;
- отображение даты, countdown, current phase;
- debug panel;
- ручной выбор локации;
- ручной override времени;
- переключение test fixtures;
- вывод рассчитанных маркеров и сегментов.

### 12.3. Что такое debug panel

Debug panel должна показывать:

- latitude / longitude;
- timezone;
- local time;
- Hijri date;
- Maghrib;
- Isha;
- Islamic midnight;
- Last third start;
- Fajr;
- Sunrise;
- Dhuhr;
- Asr;
- current phase;
- next transition;
- countdown;
- progress 0..1;
- marker angles;
- segment angles.

### 12.4. Технологии web dashboard

- React
- TypeScript
- Vite
- SVG
- Vitest
- Playwright

### 12.5. Хостинг веба

На старте web dashboard можно хостить на **GitHub Pages**.

Использовать для:

- demo;
- documentation;
- visual testing;
- public landing later.

Не использовать GitHub Pages как основу для:

- SaaS;
- backend;
- ecommerce;
- чувствительных транзакций.

---

## 13. Wear OS watch face

### 13.1. Почему это главный первый релиз

Потому что исходная идея продукта — именно **watch face**.

Твой UI отлично ложится в watch face:

- кольцо на весь экран;
- сектора суток;
- метки;
- дата;
- countdown.

### 13.2. Ограничения и платформа

Для Wear OS нужно ориентироваться на актуальные ограничения платформы и формат **Watch Face Format (WFF)**.

Важно:
- web UI не переносится напрямую как watch face UI;
- переносится логика и visual model;
- layout watch face придётся адаптировать под платформу.

### 13.3. Что должно быть в Wear release v1

- один основной layout;
- один theme;
- главное кольцо;
- дата по Хиджре;
- countdown;
- current phase;
- базовые локальные настройки;
- одна стабильная visual hierarchy.

### 13.4. Что не делать в первой версии Wear

- слишком много тем;
- конфигуратор всего подряд;
- сложные анимации;
- тяжёлые сетевые зависимости;
- backend-зависимость.

---

## 14. Apple Watch app

### 14.1. Почему не делать первой

Потому что на Apple нельзя так же естественно сделать сторонний полноценный custom watch face, как на Wear OS.

Поэтому на Apple продуктовая форма будет другой:

- standalone watch app;
- потом small complication.

### 14.2. Что будет в Apple version

- полноэкранное кольцо в watch app;
- дата по Хиджре;
- current phase;
- next prayer countdown;
- local time мелко;
- позже complication mini-view.

### 14.3. Стек Apple

- Swift
- SwiftUI
- WidgetKit later for complication

### 14.4. Зачем нужна Apple версия

- выше вероятность платёжеспособной аудитории;
- лучше ARPU в среднем;
- хорошее второе направление после проверки спроса на Wear.

---

## 15. Приложение на телефоне: нужно ли

### 15.1. На старте

Не нужно как основной deliverable.

### 15.2. Когда может понадобиться

Позже телефонное приложение может стать:

- companion для настроек;
- payment entrypoint;
- большим preview кольца;
- support surface.

Но это не должно тормозить основной релиз.

---

## 16. Тестирование

Тестирование должно быть многоуровневым.

### 16.1. Unit tests for core

Это самые важные тесты.

Покрыть:

- Hijri date conversion;
- prayer time computation adapter behavior;
- переход в новый исламский день на локальном Maghrib;
- Islamic midnight;
- Last third start;
- current phase;
- next transition;
- countdown;
- progress calculation;
- marker order;
- segment boundaries.

### 16.2. Edge cases

Обязательные кейсы:

- 1 минута до Maghrib;
- ровно Maghrib;
- 1 минута после Maghrib;
- до Fajr;
- ровно Fajr;
- перед Sunrise;
- после Sunrise;
- ровно Dhuhr;
- ровно Asr;
- Ramadan cases if logic changes affect display;
- timezone transitions;
- DST transitions;
- разные сезоны.

### 16.3. Snapshot tests

Нужны snapshot tests на итоговые JSON snapshots.

Это позволит:

- фиксировать эталонные outputs;
- использовать их позже как reference для Wear / Apple реализации.

### 16.4. Visual tests for web

Использовать Playwright:

- screenshot regression;
- different viewport sizes;
- different simulated scenarios;
- check overlap issues;
- check ring rendering.

### 16.5. Manual exploratory testing

Через web dashboard:

- перематывать время;
- переключать локации;
- смотреть реальные углы и transitions;
- проверять ожидаемость поведения.

### 16.6. Wear OS testing

- Android Studio emulator;
- manual testing on emulator;
- performance checks;
- round screen fit;
- glanceability checks.

### 16.7. Apple Watch testing

- Xcode Simulator;
- потом физические часы жены, если поддерживаются и доступны для pairing/signing.

---

## 17. Где и как тестировать физически

### 17.1. Wear OS

- сначала Android Studio emulator;
- потом physical device later if purchased or available.

### 17.2. Apple Watch

- сначала simulator;
- потом реальные Apple Watch жены.

Проверить заранее:

- поддерживается ли модель часов;
- есть ли Mac;
- есть ли Xcode;
- есть ли доступ к pairing/signing.

---

## 18. CI/CD и автоматизация

### 18.1. GitHub Actions

Сделать workflows для:

- lint;
- unit tests;
- build web-dashboard;
- visual tests if feasible;
- deploy web-dashboard to GitHub Pages.

### 18.2. Recommended pipelines

#### CI on pull request
- install
- lint
- unit tests
- typecheck
- build

#### Main branch deploy
- build web-dashboard
- deploy to GitHub Pages

### 18.3. Release process later

Позже добавить:

- tagged releases;
- changelog generation;
- release artifacts;
- watchface packaging pipeline.

---

## 19. Продажа и монетизация

### 19.1. Первая продажа

Первый коммерческий релиз — **Wear OS watch face**.

Причины:

- это самая естественная форма продукта;
- минимальная концептуальная деформация;
- лучшее совпадение между идеей и платформой.

### 19.2. Что продавать на Wear OS

Возможные модели:

- paid watch face;
- free + premium unlock later;
- base face + premium themes later.

Для первого релиза лучше simplest path:

- либо платный face;
- либо очень простая монетизация без сложных внутренних уровней.

### 19.3. Apple monetization later

Для Apple later:

- paid app;
- premium unlock;
- in-app purchase for digital functionality.

### 19.4. Когда можно продавать

Продавать можно, когда есть:

- стабильный основной экран;
- корректные расчёты;
- support page;
- screenshots;
- store description;
- privacy notes;
- basic branding.

### 19.5. Что нужно перед первой продажей

- зафиксировать MVP scope;
- иметь reproducible builds;
- иметь docs/FAQ;
- иметь support email or support page;
- проверить реальные device screenshots;
- проверить UX glanceability.

---

## 20. Инфраструктура

### 20.1. На старте

Минимальная инфраструктура:

- GitHub repository;
- GitHub Actions;
- GitHub Pages;
- Android Studio;
- later Xcode on Mac.

### 20.2. Чего не нужно на старте

- VPS;
- cloud DB;
- Redis;
- queue;
- Kubernetes;
- monitoring stack;
- auth service.

### 20.3. Что может понадобиться позже

Если проект вырастет:

- API service;
- DB for settings/users;
- analytics;
- crash reporting;
- support website;
- payment / entitlement sync backend.

---

## 21. Пошаговый roadmap

### Phase 0 — Product freeze

Нужно зафиксировать:

- Umm al-Qura for Hijri date;
- local Maghrib as day switch;
- prayer times by geolocation;
- Maghrib at the top of ring;
- Islamic Midnight as secondary marker;
- Last Third as secondary arc;
- no Fajr Safety Cutoff in v1.

### Phase 1 — Core package

Сделать `packages/core`:

1. типы
2. calendar conversion
3. prayer times adapter
4. Islamic day bounds
5. derived markers
6. current phase
7. next transition
8. countdown
9. ring geometry
10. formatting helpers
11. full snapshot builder

### Phase 2 — Tests and fixtures

Сделать `packages/test-fixtures`:

1. fixture schema
2. fixed scenarios
3. JSON snapshots
4. regression suite

### Phase 3 — Web dashboard

Сделать `apps/web-dashboard`:

1. ring renderer
2. center info block
3. debug panel
4. fixture switcher
5. manual time override
6. manual location input
7. GitHub Pages deployment

### Phase 4 — Visual polishing

1. validate marker hierarchy
2. validate text fit
3. validate ring readability
4. validate phase color coding
5. validate on different circular layouts visually

### Phase 5 — Wear OS productization

1. study target watch face constraints
2. map core output to watch face representation
3. implement first watch face layout
4. run emulator tests
5. prepare store assets
6. release

### Phase 6 — Sales validation

1. observe feedback
2. identify confusion points
3. identify desired settings
4. identify which features actually matter

### Phase 7 — Apple Watch version

1. create SwiftUI watch app
2. port or replicate presentation logic using core outputs as reference
3. implement full-screen ring
4. add small complication later
5. prepare App Store monetization flow

### Phase 8 — Backend only if needed

Only if there is evidence of need.

Possible backend features:
- sync settings
- purchase entitlements
- analytics
- support/admin tools

---

## 22. Dev principles for implementation

### 22.1. Golden rule

**Переносимой должна быть логика, а не вёрстка.**

### 22.2. UI independence

Нельзя смешивать:

- расчёт prayer times,
- геометрию кольца,
- React state,
- platform APIs.

### 22.3. Minimalism

Каждая первая версия должна быть минимальной:

- один layout;
- одна visual system;
- без лишних опций.

### 22.4. Honest model

Нужно явно документировать:

- Hijri date: Umm al-Qura
- day switch: local Maghrib
- prayer times: local geolocation-based calculation

### 22.5. No fake backend

Не придумывать backend “на вырост”, если нет реальной потребности.

---

## 23. Требования к README / promptability

Этот файл должен использоваться как источник правды для дальнейшей реализации через ChatGPT / Codex.

Поэтому:

- не уходить от этой архитектуры без явного решения;
- любые изменения scope фиксировать в этом README;
- перед генерацией кода всегда сначала проверять соответствие этой модели.

---

## 24. MVP acceptance criteria

MVP считается готовым, если выполнено всё ниже:

1. есть `core`, который на входе принимает `now + location + timezone`;
2. core возвращает корректный JSON snapshot исламских суток;
3. дата по Хиджре считается по Umm al-Qura;
4. исламские сутки переключаются на локальном Maghrib;
5. prayer times считаются по геолокации;
6. ring progress считается от `lastMaghrib` до `nextMaghrib`;
7. Islamic Midnight вычисляется корректно;
8. Last Third выделяется корректно;
9. web dashboard показывает кольцо и debug data;
10. dashboard деплоится на GitHub Pages;
11. есть unit tests и snapshots;
12. есть план порта на Wear OS watch face.

---

## 25. Первая практическая задача для реализации

Начать с `packages/core` и сделать в таком порядке:

1. types
2. fixtures
3. `getHijriDateUmmAlQura()`
4. `getPrayerTimes()`
5. `getIslamicDayBounds()`
6. `getIslamicMidnight()`
7. `getLastThirdStart()`
8. `getCurrentPhase()`
9. `getNextTransition()`
10. `getCountdown()`
11. `getIslamicDayProgress()`
12. `getMarkers()`
13. `getRingSegments()`
14. `computeIslamicDaySnapshot()`
15. unit tests
16. snapshot tests
17. only then web visualizer

---

## 26. Final strategic recommendation

Идти так:

- **TypeScript core first**
- **web visualizer second**
- **Wear OS watch face as first commercial release**
- **Apple Watch app later**
- **backend only after real need appears**

Это минимизирует повторную работу, ускоряет MVP и сохраняет задел на будущее.

