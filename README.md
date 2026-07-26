# 🕹️ RetroAOSP (NougatMod OS) для Xiaomi Redmi 7 (`onclite`)

> Интерфейс **Android 7.1 Nougat (Material Design 1, Teal 500)** на базе современного
> **LineageOS 21 (Android 14)**. Честные патчи поверх реальных исходников:
> каждая цель патча сверена с деревом `lineage-21`, ресурсы переопределяются
> штатным overlay-механизмом, а не хаками.

## Что даёт v2

| Область | Что сделано | Механизм |
|---|---|---|
| Акцент системы | Teal 500 `#009688` везде, Monet (Material You) выключен | overlay: `system_accent1_*` + `flag_monet=false` |
| Геометрия | Углы 2dp у диалогов, кнопок, уведомлений, плиток QS | overlay: `config_dialogCornerRadius`, `control_corner_material`, `notification_corner_radius`, … |
| Шторка | Сетка Quick Settings **3×3**, тонкий плоский ползунок яркости (28dp) | overlay: `quick_settings_num_columns/max_rows`, `rounded_slider_*` |
| Касание | Классическая радиальная волна без «искр» Android 12+ | патч: `FORCE_PATTERNED_STYLE=false` в `RippleDrawable.java` |
| Часы | Статус-бар: часы **справа** по умолчанию; локскрин: компактные однострочные | патч `ClockController.java` + overlay `config_doublelineClockDefault=0` |
| Навигация | Классические 3 кнопки по умолчанию | overlay: `config_navBarInteractionMode=0` |
| Лаунчер | Кнопка «Все приложения» в доке | патч: флаг `ENABLE_ALL_APPS_BUTTON_IN_HOTSEAT` → `ENABLED` |
| Настройки | Плотный список 48dp вместо карточек 88sp/28dp | overlay: `homepage_preference_*` |
| Иконки | Классические 3D-иконки CM 14.1 у системных приложений, квадратная маска | замена ресурсов по имени из манифеста каждого приложения |
| Бут-анимация | Оригинальная CM 14.1 (5 частей) **с согласованным desc.txt** | замена в `vendor/lineage/bootanimation` |
| Звуки | Tick / Lock / Unlock из Android 7 | замена в `frameworks/base/data/sounds` |
| Анимации | Ускорены (150/250/350 мс) — бонус к отзывчивости SD632 | overlay: `config_*AnimTime` |

Честные границы: меню недавних остаётся горизонтальным (это тонны Java-кода),
структура страниц Настроек — современная, но выглядит плоско и по-старому.
База — LineageOS 21 (Android 14): это последняя ветка с официальными деревьями Redmi 7.

## Почему не GitHub Actions

Лимит бесплатной джобы — 6 часов и ~80 ГБ диска. Полная сборка LineageOS требует
15–30 ч на 4 vCPU и ~250 ГБ. Поэтому CI (`validate.yml`) только линтит патчи и
еженедельно проверяет, что цели патчей не «уехали» в апстриме, а сборка — локальная.

## Локальная сборка

Требования: x86_64 Linux, 16+ ГБ RAM, **170+ ГБ свободного места на любом диске**
(даже NTFS/USB — сборка идёт внутри sparse-образа btrfs со сжатием), ~100 ГБ трафика.

```bash
./build_local.sh all            # prepare -> sync -> patch -> build (--reclaim)
# или по шагам:
./build_local.sh prepare        # создать и примонтировать сборочный том + swap
./build_local.sh sync           # repo init (lineage-21.0) + repo sync
./build_local.sh patch          # применить ретро-патчи (patches/apply.sh)
./build_local.sh build          # mka bacon, ~6-9 часов на 6-ядернике
./build_local.sh status         # мониторинг места
./build_local.sh destroy        # удалить образ, вернуть место (ZIP сохраняется рядом)
```

Готовая прошивка копируется в `RetroAOSP-out/` рядом с образом.

## Структура

```text
overlay/                 # DEVICE_PACKAGE_OVERLAYS: framework, SystemUI, Settings + обои
assets/                  # bootanimation (tar + desc.txt), звуки, иконки
patches/apply.sh         # интегратор: overlay + Java-патчи с проверкой каждой цели
local_manifests/onclite.xml  # деревья устройства/вендора/ядра (все ветки проверены)
build_local.sh           # локальная сборка на loop-томе btrfs
tests/run_all_tests.sh   # 37 проверок: синтаксис, XML, ассеты, mock-прогон apply.sh
.github/workflows/validate.yml  # линтер + слежение за апстримом lineage-21
```

## Принципы патчей v2 (уроки v1)

1. **Никаких файлов-дубликатов в `res/values`** — aapt2 падает с `duplicate resource`.
   Только `DEVICE_PACKAGE_OVERLAYS` (подключается в `device.mk` автоматически).
2. **Каждый sed проверяется**: цель не найдена и результат не применён → скрипт падает,
   а не молча продолжает. Идемпотентность гарантирована.
3. **Цели существуют в реальности**: все строки сверены с живыми исходниками
   `lineage-21` (июль 2026), CI перепроверяет их еженедельно.
