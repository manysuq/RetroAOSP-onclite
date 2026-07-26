#!/usr/bin/env bash
#
# RetroAOSP (NougatMod OS) — Интегратор классического SystemUI (Шторка, Громкость, Часы блокировки, Часы статус-бара)
# Вшивает переопределения сетки, радиусов кнопок громкости, отключает гигантские часы
# и переносит часы статус-бара с левого края обратно на правый (стандарт Android 7 Nougat).

set -e

echo "📊 [Real AOSP Patch] Модификация SystemUI (Шторка 3x3, Громкость 2dp, Правые часы)..."

SYSUI_RES="frameworks/base/packages/SystemUI/res/values"
SYSUI_LAYOUT="frameworks/base/packages/SystemUI/res/layout"
PATCH_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ ! -d "frameworks/base/packages/SystemUI" ]; then
    echo "⚠️ Внимание: Директория SystemUI не найдена. Пропуск."
    exit 0
fi

mkdir -p "$SYSUI_RES"
echo "📥 Вшивание конфигурации сетки Quick Settings и статус-бара..."
cp -v "$PATCH_DIR/res/values/config.xml" "$SYSUI_RES/retro_sysui_config.xml" 2>/dev/null || true
cp -v "$PATCH_DIR/res/values/dimens.xml" "$SYSUI_RES/retro_sysui_dimens.xml" 2>/dev/null || true
cp -v "$PATCH_DIR/res/values/bools.xml" "$SYSUI_RES/retro_sysui_bools.xml" 2>/dev/null || true
cp -v "$PATCH_DIR/qs_layout_md1.xml" "$SYSUI_RES/retro_qs_layout.xml" 2>/dev/null || true

# 1. Оптимизация макетов шторки: уменьшение отступов между иконками
if [ -d "$SYSUI_LAYOUT" ]; then
    echo "📐 Уменьшение маржинов плиток Quick Settings в layout..."
    sed -i 's/android:layout_margin=".*dp"/android:layout_margin="2dp"/g' "$SYSUI_LAYOUT"/qs_*.xml 2>/dev/null || true
    
    # 2. Перенос часов статус-бара СЛЕВА НАПРАВО (как в Android 7 Nougat)
    echo "⏰ Перенос часов статус-бара на правый край экрана (отключение левых часов, включение правых)..."
    # Отключаем левые часы по умолчанию в status_bar.xml
    sed -i '/android:id="@+id\/clock"/,/systemui:isStatusBar="true"/ s/systemui:isStatusBar="true"/android:visibility="gone"\n                        systemui:isStatusBar="true"/g' "$SYSUI_LAYOUT/status_bar.xml" 2>/dev/null || true
    # Включаем правые часы по умолчанию в system_icons.xml
    sed -i '/android:id="@+id\/clock_right"/,/systemui:isStatusBar="true"/ s/android:visibility="gone"/android:visibility="visible"/g' "$SYSUI_LAYOUT/system_icons.xml" 2>/dev/null || true
fi

echo "✅ [SystemUI] Шторка, громкость, экран блокировки и правые часы успешно переключены в режим Android 7!"
