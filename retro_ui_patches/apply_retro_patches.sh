#!/usr/bin/env bash
#
# RetroAOSP (NougatMod OS) — Полный инженерный интегратор ретро-интерфейса
# Применяет все визуальные, аудио и геометрические трансформации Material Design 1 к исходникам Android 16.

set -e

echo "=========================================================="
echo " 🚀 Применение полного пакета RetroAOSP (Android 7 UI & Audio)"
echo "=========================================================="

if [ ! -d "frameworks/base" ]; then
    echo "❌ Ошибка: Директория frameworks/base не найдена."
    echo "Пожалуйста, запускайте этот скрипт из корня исходного кода Android (AOSP/LineageOS)."
    exit 1
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# 1. Глобальные системные темы, скругления 2dp, палитра Teal 500 и 3-кнопочная навигация
echo "📦 1/11: Переопределение глобальной темы Theme.DeviceDefault (frameworks/base/core/res)..."
TARGET_DIR="frameworks/base/core/res/res/values"
mkdir -p "$TARGET_DIR"
cp -v "$ROOT_DIR/retro_ui_patches/themes_device_defaults_md1.xml" "$TARGET_DIR/retro_themes_device_defaults.xml"
cp -v "$ROOT_DIR/retro_ui_patches/res_dimens_md1.xml" "$TARGET_DIR/retro_dimens.xml"
cp -v "$ROOT_DIR/retro_ui_patches/res_colors_md1.xml" "$TARGET_DIR/retro_colors.xml"
cp -v "$ROOT_DIR/retro_ui_patches/res_config_md1.xml" "$TARGET_DIR/retro_config.xml"

# 2. Модификация графического движка RippleDrawable (удаление искр и шума)
echo "🌊 2/11: Модификация RippleDrawable (чистая радиальная волна касания)..."
bash "$ROOT_DIR/ripple_patches/patch_ripple_drawable.sh"

# 3. Интеграция классических иконок и отключение адаптивной маскировки
echo "📦 3/11: Установка классического пакета иконок Android 7 Nougat..."
bash "$ROOT_DIR/icon_pack_patches/install_classic_icons.sh"

# 4. Реальная модификация кода и ресурсов Launcher3 / Trebuchet (возврат кнопки 6 точек в Hotseat)
echo "🏠 4/11: Инженерная модификация Java и XML кода лаунчера (Trebuchet / Launcher3)..."
bash "$ROOT_DIR/launcher3_patches/patch_launcher3.sh"

# 5. Модификация приложения Настройки: удаление CollapsingToolbarLayout
echo "⚙️ 5/11: Переверстка приложения Настройки (Settings)..."
bash "$ROOT_DIR/settings_patches/patch_settings.sh"

# 6. Модификация SystemUI: шторка 3x3, громкость 2dp, ползунок яркости 24dp и правые часы
echo "📊 6/11: Настройка параметров и макетов SystemUI..."
bash "$ROOT_DIR/systemui_patches/patch_systemui.sh"

# 7. Модификация остальных штатных приложений: Калькулятор, Часы, Контакты, Звонилка, Файлы
echo "📱 7/11: Адаптация всех стандартных системных приложений AOSP под Material Design 1..."
bash "$ROOT_DIR/system_apps_patches/patch_all_system_apps.sh"

# 8. Установка локальных классических обоев с абстрактными волнами
echo "🖼️ 8/11: Интеграция фирменных локальных обоев Material Waves..."
bash "$ROOT_DIR/wallpapers/install_retro_wallpapers.sh"

# 9. Установка классической анимации загрузки из CyanogenMod 14.1
echo "🎬 9/11: Интеграция классической анимации загрузки Android 7 Nougat..."
bash "$ROOT_DIR/bootanimation_patches/install_retro_bootanim.sh"

# 10. Установка классических системных звуковых эффектов касания и блокировки
echo "🔊 10/11: Вшивание оригинальных системных звуковых эффектов CyanogenMod 14.1..."
bash "$ROOT_DIR/audio_patches/install_retro_sounds.sh"

# 11. Фиксация плотности пикселей экрана (320 DPI / XHDPI) для Redmi 7
echo "🖥️ 11/11: Фиксация аппаратной плотности экрана ro.sf.lcd_density=320 в конфигурациях сборки..."
for PROP_FILE in $(find build/make/target/product device/xiaomi vendor/xiaomi -name "*.mk" -o -name "*.prop" 2>/dev/null || true); do
    if grep -q "ro.sf.lcd_density" "$PROP_FILE" 2>/dev/null; then
        sed -i 's/ro.sf.lcd_density=.*/ro.sf.lcd_density=320/g' "$PROP_FILE" || true
    fi
done
# Также вшиваем системный дефолт в build.prop
mkdir -p system/sepolicy 2>/dev/null || true
echo "PRODUCT_PROPERTY_OVERRIDES += ro.sf.lcd_density=320" >> build/make/target/product/handheld_product.mk 2>/dev/null || true

echo "=========================================================="
echo " ✅ Все 11 модулей RetroAOSP успешно интегрированы в исходный код!"
echo " Теперь можно запускать компиляцию: mka bacon / mka rom"
echo "=========================================================="
