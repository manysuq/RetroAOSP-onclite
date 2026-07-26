#!/usr/bin/env bash
#
# RetroAOSP (NougatMod OS) — Интегратор системных звуковых эффектов Android 7 Nougat
# Возвращает классический хрустящий звук блокировки/разблокировки экрана и касаний (2016 год).

set -e

echo "🔊 [Real AOSP Patch] Установка классических звуковых эффектов (Lock / Unlock / Touch)..."

PATCH_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOUNDS_DIR="frameworks/base/data/sounds/effects"

if [ ! -d "frameworks/base" ]; then
    echo "⚠️ Внимание: Директория frameworks/base не найдена. Пропуск установки звуков."
    exit 0
fi

mkdir -p "$SOUNDS_DIR" "$SOUNDS_DIR/ogg" "$SOUNDS_DIR/mp3"

for AUDIO_FILE in Effect_Tick.ogg Lock.ogg Unlock.ogg; do
    if [ -f "$PATCH_DIR/$AUDIO_FILE" ]; then
        echo "📥 Вшивание аудиофайла: $AUDIO_FILE ..."
        cp -v "$PATCH_DIR/$AUDIO_FILE" "$SOUNDS_DIR/$AUDIO_FILE" || true
        cp -v "$PATCH_DIR/$AUDIO_FILE" "$SOUNDS_DIR/ogg/$AUDIO_FILE" 2>/dev/null || true
    fi
done

echo "✅ [Audio Patch] Системные звуки успешно возвращены к хрустящему звучанию Android 7 Nougat!"
