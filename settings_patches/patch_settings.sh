#!/usr/bin/env bash
#
# RetroAOSP (NougatMod OS) — Инженерный модификатор Настроек и библиотеки SettingsLib
# Возвращает плотные списки (48dip вместо 88sp/72dip), отключает овальные карточки
# и убирает скругления (28dp -> 0dp/2dp) в главном меню Settings и SettingsLib.

set -e

echo "⚙️ [Real AOSP Patch] Адаптация Settings и SettingsLib под Material Design 1 (Android 7)..."

SETTINGS_DIR="packages/apps/Settings"
SETTINGSLIB_DIR="frameworks/base/packages/SettingsLib"
PATCH_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 1. Модификация SettingsLib (корень всех кнопок и карточек в Настройках и Системных приложениях)
if [ -d "$SETTINGSLIB_DIR/res" ]; then
    echo "🏛️ Модификация SettingsLib (устранение овальных кнопок и скруглений карточек)..."
    find "$SETTINGSLIB_DIR/res" -type f -name "dimens.xml" -exec sed -i 's/<dimen name="button_corner_radius">.*<\/dimen>/<dimen name="button_corner_radius">2dp<\/dimen>/g' {} + 2>/dev/null || true
    find "$SETTINGSLIB_DIR/res" -type f -name "dimens.xml" -exec sed -i 's/<dimen name="broadcast_dialog_btn_radius">.*<\/dimen>/<dimen name="broadcast_dialog_btn_radius">2dp<\/dimen>/g' {} + 2>/dev/null || true
    find "$SETTINGSLIB_DIR/res" -type f -name "dimens.xml" -exec sed -i 's/<dimen name="preference_card_radius">.*<\/dimen>/<dimen name="preference_card_radius">0dp<\/dimen>/g' {} + 2>/dev/null || true
    find "$SETTINGSLIB_DIR/res" -type f -name "dimens.xml" -exec sed -i 's/<dimen name="search_bar_corner_radius">.*<\/dimen>/<dimen name="search_bar_corner_radius">2dp<\/dimen>/g' {} + 2>/dev/null || true
fi

# 2. Модификация приложения Settings (Главное меню и списки)
if [ -d "$SETTINGS_DIR/res" ]; then
    echo "📋 Возврат классической плотности главной страницы и списков Settings (88sp/72dip -> 48sp/48dip)..."
    
    # КРИТИЧЕСКИ ВАЖНО: Убираем раздутые гигантские карточки на главной странице Настроек
    find "$SETTINGS_DIR/res" -type f -name "dimens.xml" -exec sed -i 's/<dimen name="homepage_preference_corner_radius">.*<\/dimen>/<dimen name="homepage_preference_corner_radius">0dp<\/dimen>/g' {} + 2>/dev/null || true
    find "$SETTINGS_DIR/res" -type f -name "dimens.xml" -exec sed -i 's/<dimen name="homepage_preference_min_height">.*<\/dimen>/<dimen name="homepage_preference_min_height">48sp<\/dimen>/g' {} + 2>/dev/null || true
    find "$SETTINGS_DIR/res" -type f -name "dimens.xml" -exec sed -i 's/<dimen name="search_bar_corner_radius">.*<\/dimen>/<dimen name="search_bar_corner_radius">2dp<\/dimen>/g' {} + 2>/dev/null || true
    find "$SETTINGS_DIR/res" -type f -name "dimens.xml" -exec sed -i 's/<dimen name="rect_button_radius">.*<\/dimen>/<dimen name="rect_button_radius">2dp<\/dimen>/g' {} + 2>/dev/null || true
    
    # Стандартные списки
    find "$SETTINGS_DIR/res" -type f -name "themes*.xml" -exec sed -i 's/<item name="android:listPreferredItemHeight">72dip<\/item>/<item name="android:listPreferredItemHeight">48dip<\/item>/g' {} + 2>/dev/null || true
    find "$SETTINGS_DIR/res" -type f -name "themes*.xml" -exec sed -i 's/<item name="android:listPreferredItemHeight">56dip<\/item>/<item name="android:listPreferredItemHeight">48dip<\/item>/g' {} + 2>/dev/null || true
    
    mkdir -p "$SETTINGS_DIR/res/values"
    cp -v "$PATCH_DIR/styles_settings_md1.xml" "$SETTINGS_DIR/res/values/retro_settings_styles.xml" 2>/dev/null || true
fi

echo "✅ [Settings & SettingsLib] Главное меню настроек избавилось от 88sp пузырей и стало плотным списком Android 7!"
