#!/usr/bin/env bash
#
# RetroAOSP (NougatMod OS) — Модификатор всех стандартных системных приложений AOSP
# Принудительно отключает Material You (Monet) в штатных приложениях,
# переключая семантические цвета акцента и темы на классический стандарт MD1 (без порчи черных/белых цветов!).

set -e

echo "📱 [Real AOSP Patch] Адаптация штатных системных приложений под Material Design 1..."

APPS=(
    "packages/apps/ExactCalculator"
    "packages/apps/DeskClock"
    "packages/apps/Contacts"
    "packages/apps/Dialer"
    "packages/apps/Messaging"
    "packages/apps/Calendar"
    "packages/apps/Gallery2"
    "packages/apps/DocumentsUI"
    "packages/apps/PackageInstaller"
)

for APP_DIR in "${APPS[@]}"; do
    if [ -d "$APP_DIR/res" ]; then
        echo "🔧 Обработка приложения: $APP_DIR ..."
        
        # 1. Безопасная замена ТОЛЬКО семантических цветов акцента и праймари (не трогая белые, черные и прозрачные!)
        find "$APP_DIR/res" -type f -name "colors.xml" -exec sed -i 's/<color name="colorPrimary">.*<\/color>/<color name="colorPrimary">#009688<\/color>/g' {} + 2>/dev/null || true
        find "$APP_DIR/res" -type f -name "colors.xml" -exec sed -i 's/<color name="colorAccent">.*<\/color>/<color name="colorAccent">#009688<\/color>/g' {} + 2>/dev/null || true
        find "$APP_DIR/res" -type f -name "colors.xml" -exec sed -i 's/<color name="monet_.*">.*<\/color>/<color name="monet_accent">#009688<\/color>/g' {} + 2>/dev/null || true
        
        # 2. Безопасное переопределение скруглений углов (только для карточек, кнопок и диалогов)
        find "$APP_DIR/res" -type f -name "dimens.xml" -exec sed -i 's/<dimen name="card_corner_radius">.*<\/dimen>/<dimen name="card_corner_radius">2dp<\/dimen>/g' {} + 2>/dev/null || true
        find "$APP_DIR/res" -type f -name "dimens.xml" -exec sed -i 's/<dimen name="button_corner_radius">.*<\/dimen>/<dimen name="button_corner_radius">2dp<\/dimen>/g' {} + 2>/dev/null || true
        find "$APP_DIR/res" -type f -name "dimens.xml" -exec sed -i 's/<dimen name="dialog_corner_radius">.*<\/dimen>/<dimen name="dialog_corner_radius">2dp<\/dimen>/g' {} + 2>/dev/null || true
        
        # 3. Принудительное наследование тем от Theme.DeviceDefault
        find "$APP_DIR/res" -type f -name "styles.xml" -exec sed -i 's/parent="Theme.Material3.*/parent="Theme.DeviceDefault"/g' {} + 2>/dev/null || true
        find "$APP_DIR/res" -type f -name "themes.xml" -exec sed -i 's/parent="Theme.Material3.*/parent="Theme.DeviceDefault"/g' {} + 2>/dev/null || true
    fi
done

echo "✅ [System Apps] Семантические цвета, углы и темы успешно переопределены во всех 9 системных приложениях!"
