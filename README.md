# 🕹️ RetroAOSP (NougatMod OS) для Xiaomi Redmi 7 (`onclite`)

> **Кастомный РОМ на базе современного Android 16 (AOSP / LineageOS) с глубокой инженерной адаптацией всей системы, графического движка и иконок под спецификации Material Design 1 (Android 5 Lollipop / Android 7 Nougat).**

---

## 💡 О проекте

**RetroAOSP** — это результат тщательного инженерного реверс-инжиниринга и исследования архитектуры AOSP. Прошивка возвращает аутентичную атмосферу 2014–2016 годов на современную стабильную и безопасную ОС:
* 🌊 **Чистый Ripple-эффект (`RippleDrawable`):** В графическом движке `frameworks/base/graphics` отключен современный шейдер "искр" и "шума" (sparkles / noise из Android 12). Возвращена классическая, чистая расходящаяся радиальная волна при касании.
* 📦 **Аутентичный икон-пак и отмена маскировки:** В ядре системы отключена маскировка `config_icon_mask`, обрезавшая значки в круги/пилюли. Все штатные приложения (Настройки, Телефон, Контакты, Калькулятор, Часы, Файлы) получают оригинальные асимметричные геометрические иконки из LineageOS 14.1 (Android 7.1.2) с эффектом сложенной бумаги и падающими тенями.
* 🏢 **Глобальная тема фреймворка (`Theme.DeviceDefault`):** Полное переопределение `themes_device_defaults.xml`. Отключен движок Monet (Material You), все окна, диалоги и кнопки жестко зафиксированы на скруглениях **2dp**, элевации **4dp/8dp** и палитре **Teal 500 (`#009688`) / Indigo (`#3F51B5`)**.
* 📱 **Адаптация всех штатных приложений:** Калькулятор (`ExactCalculator`), Часы (`DeskClock`), Контакты (`Contacts`), Звонилка (`Dialer`), Файловый менеджер (`DocumentsUI`) и Пакетный менеджер принудительно переведены на использование классической палитры и отключение макетов Material You.
* 🏠 **Лаунчер с кнопкой меню (6 точек):** Реальная модификация Java-кода (`Hotseat.java` и `FeatureFlags.java`) и XML-макетов в `Launcher3`, возвращающая постоянную кнопку **All Apps** в центр дока и отключающая свайп вверх.
* ⚙️ **Классические Настройки (`Settings`):** Выпилен огромный двухстрочный `CollapsingToolbarLayout`, возвращен плотный однострочный список (высота строк 48dp), фирменная шапка `ActionBar` (56dp) и бирюзовые переключатели.
* 📊 **Шторка и Статус-бар (`SystemUI`):** Использованы реальные конфигурации AOSP (`quick_settings_num_columns` и `notification_scrim_corner_radius`). Овальные пилюли заменены на сетку 3x3, радиусы уведомлений снижены до 2dp/0dp, возвращен тонкий шрифт часов `sans-serif-light` (Roboto Light).
* 🖼️ **Фирменные обои:** Автоматическая установка оригинальных абстрактных волн (Lollipop/Marshmallow/Nougat) в качестве стандартного фона `default_wallpaper.png`.

---

## 📁 Архитектура 8 инженерных модулей

```text
RetroAOSP-onclite/
├── .github/workflows/
│   └── build_rom.yml           # Облачный робот автосборки прошивки на серверах GitHub Actions
├── local_manifests/
│   └── onclite.xml             # Деревья устройства, вендора и ядра Redmi 7 (Snapdragon 632)
├── ripple_patches/
│   └── patch_ripple_drawable.sh # Отключение искрящегося шума и возврат чистой волны касания
├── icon_pack_patches/
│   └── install_classic_icons.sh # Отключение маски Adaptive Icons и установка значков Nougat
├── launcher3_patches/
│   ├── ic_allapps_md1.xml      # Векторная иконка "6 точек" для меню приложений
│   └── patch_launcher3.sh      # Инженерный патчер Java и XML для Launcher3
├── settings_patches/
│   ├── res/values/themes.xml   # Реальная замена тем Настроек без CollapsingToolbar
│   └── patch_settings.sh       # Интегратор Настроек
├── system_apps_patches/
│   └── patch_all_system_apps.sh # Адаптор для Калькулятора, Часов, Контактов, Звонилки и Файлов
├── systemui_patches/
│   ├── res/values/config.xml   # Конфигурация сетки 3x3
│   ├── res/values/dimens.xml   # Реальные размеры AOSP (углы 2dp, статус-бар 24dp)
│   └── patch_systemui.sh       # Интегратор SystemUI
├── wallpapers/
│   └── install_retro_wallpapers.sh # Загрузчик классических обоев
├── retro_ui_patches/
│   ├── apply_retro_patches.sh  # Главный мастер-скрипт, запускающий все 8 модулей
│   ├── themes_device_defaults_md1.xml # Глобальное переопределение Theme.DeviceDefault
│   ├── res_dimens_md1.xml      # Строгие скругления 2dp
│   ├── res_colors_md1.xml      # Палитра Teal #009688
│   └── res_config_md1.xml      # Включение 3-кнопочной навигации
└── build_rom.sh                # Локальный/серверный скрипт сборки
```
