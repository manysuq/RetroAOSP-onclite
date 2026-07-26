#!/usr/bin/env bash
#
# RetroAOSP (NougatMod OS) — Интегратор классической анимации загрузки
# Подменяет современную анимацию LineageOS на оригинальную анимацию CyanogenMod 14.1 (Android 7 Nougat).

set -e

echo "🎬 [Real AOSP Patch] Установка классической анимации загрузки Android 7 Nougat..."

PATCH_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOCAL_TAR="$PATCH_DIR/bootanimation.tar"
VENDOR_DIR="vendor/lineage/bootanimation"

if [ ! -d "$VENDOR_DIR" ]; then
    echo "⚠️ Внимание: Директория $VENDOR_DIR не найдена. Пропуск установки анимации."
    exit 0
fi

if [ -f "$LOCAL_TAR" ]; then
    echo "📥 Замена современного архива bootanimation.tar в $VENDOR_DIR на версию из CyanogenMod 14.1 (9.8 МБ)..."
    cp -v "$LOCAL_TAR" "$VENDOR_DIR/bootanimation.tar"
    echo "✅ [Boot Animation] Классическая анимация загрузки успешно вшита! При включении телефона пользователя встретит ретро-заставка 2016 года!"
else
    echo "❌ Ошибка: Локальный файл $LOCAL_TAR не найден."
    exit 1
fi
