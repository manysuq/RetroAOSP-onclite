#!/usr/bin/env bash
#
# RetroAOSP (NougatMod OS) — Интегратор классических обоев Android (Material Waves)
# Вшивает локальный оригинальный фон из CyanogenMod 14.1 (Android 7 Nougat) как стандартный фон системы.

set -e

echo "🖼️ Интеграция классических обоев Material Design 1 (Nougat Waves)..."

WALLPAPER_DIR="frameworks/base/core/res/res/drawable-nodpi"
PATCH_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOCAL_WALLPAPER="$PATCH_DIR/default_wallpaper.png"

if [ ! -d "frameworks/base/core/res/res" ]; then
    echo "⚠️ Внимание: Директория системных ресурсов не найдена. Пропуск установки обоев."
    exit 0
fi

mkdir -p "$WALLPAPER_DIR" "frameworks/base/core/res/res/drawable-sw600dp-nodpi" "frameworks/base/core/res/res/drawable-sw720dp-nodpi"

if [ -f "$LOCAL_WALLPAPER" ]; then
    echo "📥 Вшивание локального оригинального файла обоев (479 КБ) из CyanogenMod 14.1..."
    cp -v "$LOCAL_WALLPAPER" "$WALLPAPER_DIR/default_wallpaper.png"
    cp -v "$LOCAL_WALLPAPER" "frameworks/base/core/res/res/drawable-sw600dp-nodpi/default_wallpaper.png" 2>/dev/null || true
    cp -v "$LOCAL_WALLPAPER" "frameworks/base/core/res/res/drawable-sw720dp-nodpi/default_wallpaper.png" 2>/dev/null || true
    echo "✅ [Wallpapers] Классические обои Nougat успешно установлены во все разрешения!"
else
    echo "❌ Ошибка: Локальный файл $LOCAL_WALLPAPER не найден."
    exit 1
fi
