# Islamic Day Watch Face (Wear OS)

> **Поддержка приостановлена.** Сейчас активная разработка только для **веб-дашборда** и **Apple Watch**. Когда понадобится синхронизировать с Android — поддержку возобновим. Код оставлен в репозитории.

Циферблат для Wear OS с исламским днём (Maghrib → Maghrib), Hijri датой и кольцом фаз.

## Watch Face Format (WFF)

Циферблат использует **Watch Face Format** — декларативный XML-формат для Wear OS 4+. Логика (Hijri, prayer times, ring progress) реализована через `ComplicationDataSourceService`.

## Требования

- **JDK 17** (или выше) — для сборки
- **Android Studio** (рекомендуется) — для эмулятора и отладки
- **Android SDK** с API 30+

## Структура (WFF split)

- **watchface** — resource-only APK (`hasCode=false`), `com.islamicdaydial.watchface` — индексируется системой как циферблат
- **app** — APK с кодом (`com.islamicdaydial.watchface.app`) — MainActivity, ComplicationDataSourceService

Оба APK должны быть установлены.

## Сборка

```bash
./gradlew assembleDebug
```

## Тестирование без физического устройства

### 1. Unit-тесты (JVM)

Тесты core-логики (Hijri, prayer times, phases, ring) запускаются на JVM без эмулятора:

```bash
./gradlew testDebugUnitTest
```

### 2. Эмулятор Wear OS

**Важно:** используйте **API 33 или 34** — на API 30 sideloaded циферблаты часто не появляются в списке.

1. Откройте **Android Studio**
2. **Tools → Device Manager** (или AVD Manager)
3. **Create Device** → выберите категорию **Wear OS**
4. Выберите устройство (например, **Wear OS Large Round**)
5. Выберите системный образ с **API 33** или **API 34** (не API 30)
6. Завершите создание AVD

### 3. Установка на эмулятор

Установите **оба** APK (watchface + app):

```bash
./gradlew installAll
```

Или по отдельности:

```bash
./gradlew :watchface:installDebug :app:installDebug
```

Или из Android Studio: **Run → Run 'app'** (установит только app; для WFF нужен ещё watchface).

### 4. Активация циферблата

**Эмулятор:** WFF-циферблат может не появляться в picker. Используйте ADB broadcast для принудительной активации:

```bash
adb shell am broadcast -a com.google.android.wearable.app.DEBUG_SURFACE \
  --es operation set-watchface --es watchFaceId com.islamicdaydial.watchface
```

**Физическое устройство:** откройте Islamic Day → «Установить циферблат» → выберите Islamic Day в списке (если отображается).

## Структура проекта

```
watchface/src/main/          # Resource-only (hasCode=false)
├── res/raw/watchface.xml
├── res/xml/watch_face_info.xml
└── AndroidManifest.xml

app/src/main/
├── res/                     # Дубликаты для app (если нужны)
└── java/.../watchface/
    ├── IslamicDayComplicationDataSourceService.kt  # Данные для complications
    ├── MainActivity.kt
    └── core/IslamicDayCore.kt         # Hijri, prayer times, phases, ring

app/src/test/.../core/
├── NightMarkersTest.kt, PhasesTest.kt, RingTest.kt, SnapshotTest.kt
```

## Локация по умолчанию

Сейчас используется фиксированная локация **Стамбул** (41.0082, 28.9784). В будущем можно добавить получение GPS с устройства.

## Зависимости

- `com.batoulapps.adhan:adhan` — расчёт времени намаза (Umm Al-Qura)
- `com.github.msarhan:ummalqura-calendar` — Hijri календарь
- `androidx.wear.watchface` — Jetpack Watch Face Library
