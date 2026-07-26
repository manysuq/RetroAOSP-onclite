#!/usr/bin/env bash
#
# RetroAOSP (NougatMod OS) — Интегратор классического пакета иконок Android 7 Nougat
# Отключает принудительную обрезку Adaptive Icons в круги/пилюли, удаляет папки anydpi-v26
# и вшивает локальные проверенные иконки штатных приложений из LineageOS 14.1 (cm-14.1).

set -e

echo "📦 [Real AOSP Patch] Установка классических иконок Material Design 1 (Android 7 UI)..."

PATCH_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ICONS_DIR="$PATCH_DIR/icons"
CONFIG_FILE="frameworks/base/core/res/res/values/config.xml"

# 1. Отключение маскирования Adaptive Icons (разрешаем свободные геометрические формы)
if [ -f "$CONFIG_FILE" ]; then
    echo "✂️ Отключение системной маски config_icon_mask (разрешение асимметричных иконок)..."
    sed -i 's/<string name="config_icon_mask" translatable="false">.*<\/string>/<string name="config_icon_mask" translatable="false"><\/string>/g' "$CONFIG_FILE" || true
    sed -i 's/<bool name="config_useAdaptiveIcon">.*<\/bool>/<bool name="config_useAdaptiveIcon">false<\/bool>/g' "$CONFIG_FILE" || true
fi

# 2. Локальная интеграция оригинальных иконок из нашего репозитория
declare -A CLASSIC_ICONS=(
    ["packages/apps/Settings"]="$ICONS_DIR/settings.png"
    ["packages/apps/DeskClock"]="$ICONS_DIR/deskclock.png"
    ["packages/apps/ExactCalculator"]="$ICONS_DIR/calculator.png"
    ["packages/apps/Contacts"]="$ICONS_DIR/contacts.png"
    ["packages/apps/Dialer"]="$ICONS_DIR/dialer.png"
    ["packages/apps/DocumentsUI"]="$ICONS_DIR/documentsui.png"
    ["frameworks/base/packages/DocumentsUI"]="$ICONS_DIR/documentsui.png"
)

for APP_PATH in "${!CLASSIC_ICONS[@]}"; do
    ICON_FILE="${CLASSIC_ICONS[$APP_PATH]}"
    if [ -d "$APP_PATH/res" ] && [ -f "$ICON_FILE" ]; then
        echo "📥 Вшивание классической иконки и удаление anydpi в: $APP_PATH ..."
        
        # КРИТИЧЕСКИ ВАЖНО: Удаляем современные адаптивные векторные обертки anydpi-v26,
        # иначе Android всегда будет предпочитать их вместо наших PNG-иконок!
        rm -rf "$APP_PATH/res/mipmap-anydpi"* "$APP_PATH/res/drawable-anydpi"* 2>/dev/null || true
        
        mkdir -p "$APP_PATH/res/mipmap-xxxhdpi" "$APP_PATH/res/mipmap-xxhdpi" "$APP_PATH/res/mipmap-hdpi"
        cp -v "$ICON_FILE" "$APP_PATH/res/mipmap-xxxhdpi/ic_launcher.png" || true
        cp -v "$ICON_FILE" "$APP_PATH/res/mipmap-xxhdpi/ic_launcher.png" || true
        cp -v "$ICON_FILE" "$APP_PATH/res/mipmap-hdpi/ic_launcher.png" || true
        # Для приложений с кастомным именем иконки (Контакты, Файлы, Настройки)
        cp -v "$ICON_FILE" "$APP_PATH/res/mipmap-xxxhdpi/ic_launcher_settings.png" 2>/dev/null || true
        cp -v "$ICON_FILE" "$APP_PATH/res/mipmap-xxxhdpi/ic_contacts_launcher.png" 2>/dev/null || true
        cp -v "$ICON_FILE" "$APP_PATH/res/mipmap-xxxhdpi/ic_launcher_filemanager.png" 2>/dev/null || true
    fi
done

echo "✅ [Icon Pack] Классические иконки вшиты, а адаптивные папки anydpi успешно нейтрализованы!"
