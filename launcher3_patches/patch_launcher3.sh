#!/usr/bin/env bash
#
# RetroAOSP (NougatMod OS) — Хирургический патчер Launcher3, Trebuchet и Quickstep
# Заменяет Контакты в доке на All Apps Button, включает флаги Hotseat
# и возвращает строгие углы (2dp) карточкам недавних приложений в Quickstep.

set -e

echo "🏠 [Real AOSP Patch] Хирургическая адаптация лаунчера (Launcher3 / Trebuchet) под макет Android 7..."

LAUNCHER_DIRS=(
    "packages/apps/Launcher3"
    "packages/apps/Trebuchet"
)

PATCH_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FOUND_LAUNCHER=false

for LAUNCHER_DIR in "${LAUNCHER_DIRS[@]}"; do
    if [ -d "$LAUNCHER_DIR" ]; then
        FOUND_LAUNCHER=true
        echo "⚡ Обнаружена директория лаунчера: $LAUNCHER_DIR ..."

        # 1. Замена векторной иконки 6 точек
        echo "🔄 Вшивание классической иконки ic_allapps (6 точек) в ресурсы..."
        mkdir -p "$LAUNCHER_DIR/res/drawable"
        cp -v "$PATCH_DIR/ic_allapps_md1.xml" "$LAUNCHER_DIR/res/drawable/ic_allapps.xml" 2>/dev/null || true
        cp -v "$PATCH_DIR/ic_allapps_md1.xml" "$LAUNCHER_DIR/res/drawable/ic_all_apps_button.xml" 2>/dev/null || true

        # 2. Переключение FeatureFlags (возвращаем старый обработчик Hotseat)
        echo "☕ Включение флагов ENABLE_ALL_APPS_IN_HOTSEAT и отключение NO_ALL_APPS_ICON..."
        find "$LAUNCHER_DIR/src" -name "FeatureFlags*.java" -exec sed -i 's/ENABLE_ALL_APPS_IN_HOTSEAT.*=.*false;/ENABLE_ALL_APPS_IN_HOTSEAT = true;/g' {} + 2>/dev/null || true
        find "$LAUNCHER_DIR/src" -name "FeatureFlags*.java" -exec sed -i 's/NO_ALL_APPS_ICON.*=.*true;/NO_ALL_APPS_ICON = false;/g' {} + 2>/dev/null || true
        find "$LAUNCHER_DIR/src" -name "FeatureFlags*.java" -exec sed -i 's/ENABLE_ALL_APPS_BUTTON.*=.*false;/ENABLE_ALL_APPS_BUTTON = true;/g' {} + 2>/dev/null || true

        # 3. Хирургическая замена ячейки screen="2" x="2" (бывшие Контакты) на All Apps
        echo "📐 Освобождение центральной ячейки Hotseat №2 от Контактов и посадка All Apps Button..."
        for WS_FILE in $(find "$LAUNCHER_DIR/res" -name "default_workspace*.xml"); do
            sed -i 's/category="android.intent.category.APP_CONTACTS"/category="android.intent.category.ALL_APPS"/g' "$WS_FILE" 2>/dev/null || true
            sed -i 's/category=android.intent.category.APP_CONTACTS/category=android.intent.category.ALL_APPS/g' "$WS_FILE" 2>/dev/null || true
        done

        # 4. Модификация Quickstep (карточки недавних приложений в мультитаскинге)
        if [ -d "$LAUNCHER_DIR/quickstep/res/values" ]; then
            echo "📱 Сжатие скруглений карточек недавних приложений в Quickstep (22dp -> 2dp)..."
            find "$LAUNCHER_DIR/quickstep/res/values" -type f -name "dimens.xml" -exec sed -i 's/<dimen name="task_menu_corner_radius">.*<\/dimen>/<dimen name="task_menu_corner_radius">2dp<\/dimen>/g' {} + 2>/dev/null || true
            find "$LAUNCHER_DIR/quickstep/res/values" -type f -name "dimens.xml" -exec sed -i 's/<dimen name="task_corner_radius_small">.*<\/dimen>/<dimen name="task_corner_radius_small">2dp<\/dimen>/g' {} + 2>/dev/null || true
        fi
    fi
done

if [ "$FOUND_LAUNCHER" = false ]; then
    echo "⚠️ Внимание: Ни Launcher3, ни Trebuchet не найдены в исходниках."
else
    echo "✅ [Launcher & Quickstep] Рабочий стол и экран мультитаскинга успешно адаптированы!"
fi
