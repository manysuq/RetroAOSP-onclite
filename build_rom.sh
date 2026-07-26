#!/usr/bin/env bash
#
# RetroAOSP (NougatMod OS) — Главный скрипт локальной / серверной сборки
# Использование: ./build_rom.sh [userdebug|eng|user]

set -e

BUILD_TYPE=${1:-userdebug}
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROM_DIR="$HOME/retro_android_build"

echo "=================================================================="
echo " 🛠️ Запуск сборки RetroAOSP для Redmi 7 (onclite) - $BUILD_TYPE"
echo "=================================================================="

# 1. Подготовка сборочной директории
mkdir -p "$ROM_DIR"
cd "$ROM_DIR"

# 2. Инициализация репозитория (если еще не инициализировано)
if [ ! -d ".repo" ]; then
    echo "📥 Инициализация исходного кода Android (LineageOS base)..."
    repo init -u https://github.com/LineageOS/android.git -b lineage-21 --git-lfs --depth=1
fi

# 3. Установка локального манифеста для Redmi 7
echo "📋 Подключение манифеста для Xiaomi Redmi 7 (onclite)..."
mkdir -p .repo/local_manifests
cp -v "$ROOT_DIR/local_manifests/onclite.xml" .repo/local_manifests/onclite.xml

# 4. Синхронизация кода
echo "🔄 Синхронизация репозиториев (repo sync)..."
repo sync -c -j$(nproc --all) --force-sync --no-clone-bundle --no-tags

# 5. Применение ретро-патчей Material Design 1
echo "🎨 Наложение патчей Material Design 1 (Android 7 UI)..."
bash "$ROOT_DIR/retro_ui_patches/apply_retro_patches.sh"

# 6. Запуск компиляции
echo "⚡ Настройка окружения и старт компиляции (mka bacon)..."
source build/envsetup.sh
lunch lineage_onclite-$BUILD_TYPE

echo "🔥 Компиляция началась! Используем $(nproc --all) потоков процессора..."
mka bacon -j$(nproc --all)

echo "=================================================================="
echo " 🎉 Сборка успешно завершена!"
echo " Готовый архив лежит в директории: $ROM_DIR/out/target/product/onclite/"
echo "=================================================================="
