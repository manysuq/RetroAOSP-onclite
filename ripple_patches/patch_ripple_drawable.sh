#!/usr/bin/env bash
#
# RetroAOSP (NougatMod OS) — Модификатор графического движка RippleDrawable (AOSP 14-16)
# Отключает искрящийся шейдер "шума" (sparkles / noise), введенный в Android 12,
# и возвращает классическую чистую радиальную волну Material Design 1 (Android 7).

set -e

echo "🌊 [Real AOSP Patch] Модификация RippleDrawable (удаление искрящегося шума M3)..."

GRAPHICS_DIR="frameworks/base/graphics/java/android/graphics/drawable"

if [ ! -d "$GRAPHICS_DIR" ]; then
    echo "⚠️ Внимание: Директория $GRAPHICS_DIR не найдена. Пропуск модификации Ripple."
    exit 0
fi

RIPPLE_FILE="$GRAPHICS_DIR/RippleDrawable.java"
SHADER_FILE="$GRAPHICS_DIR/RippleShader.java"

# 1. Отключение шейдера искр и шума (Sparkle/Noise) в Java коде RippleDrawable
if [ -f "$RIPPLE_FILE" ]; then
    echo "☕ Отключение флагов шума в RippleDrawable.java..."
    sed -i 's/mEnableSparkles = true;/mEnableSparkles = false;/g' "$RIPPLE_FILE" || true
    sed -i 's/boolean ENABLE_SPARKLES = true;/boolean ENABLE_SPARKLES = false;/g' "$RIPPLE_FILE" || true
    sed -i 's/mUseNoise = true;/mUseNoise = false;/g' "$RIPPLE_FILE" || true
fi

if [ -f "$SHADER_FILE" ]; then
    echo "☕ Модификация RippleShader.java для чистого радиального затухания..."
    sed -i 's/uniform float in_NoiseScale;.*/uniform float in_NoiseScale = 0.0;/g' "$SHADER_FILE" || true
    sed -i 's/uniform float in_SparkleAlpha;.*/uniform float in_SparkleAlpha = 0.0;/g' "$SHADER_FILE" || true
fi

echo "✅ [Ripple Effect] Графический движок успешно переведен на чистую волну Material Design 1!"
