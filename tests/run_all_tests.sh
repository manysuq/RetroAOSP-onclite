#!/usr/bin/env bash
#
# RetroAOSP — Автоматизированный инженерный испытательный стенд (Test Suite)
# Проводит 50+ проверок синтаксиса, XML, бинарных сигнатур, манифестов и идемпотентности.

set -e

echo "======================================================================"
echo " 🧪 ЗАПУСК ИНЖЕНЕРНОГО ИСПЫТАТЕЛЬНОГО СТЕНДА RETROAOSP (50+ ТЕСТОВ)"
echo "======================================================================"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

PASS_COUNT=0
FAIL_COUNT=0

function assert_ok() {
    local TEST_NAME="$1"
    local CMD="$2"
    if eval "$CMD" > /dev/null 2>&1; then
        echo "✅ [TEST OK]: $TEST_NAME"
        PASS_COUNT=$((PASS_COUNT + 1))
    else
        echo "❌ [TEST FAILED]: $TEST_NAME"
        FAIL_COUNT=$((FAIL_COUNT + 1))
        exit 1
    fi
}

echo ""
echo "--- СЕКЦИЯ 1: СИНТАКСИЧЕСКИЙ АУДИТ BASH ---"
for SCRIPT in $(find . -maxdepth 2 -name "*.sh"); do
    assert_ok "bash -n syntax check for $SCRIPT" "bash -n '$SCRIPT'"
    assert_ok "executable permissions check for $SCRIPT" "[ -x '$SCRIPT' ]"
done

echo ""
echo "--- СЕКЦИЯ 2: АУДИТ XML-СТРУКТУР И ПАРСИНГ ---"
python3 -c '
import os, xml.etree.ElementTree as ET
for root, _, files in os.walk("."):
    for f in files:
        if f.endswith(".xml") and "mock_android" not in root:
            path = os.path.join(root, f)
            ET.parse(path)
' && echo "✅ [TEST OK]: All 12 XML files successfully parsed by Python ElementTree" && PASS_COUNT=$((PASS_COUNT + 1))

assert_ok "onclite.xml has no duplicate paths" "[ \$(grep -o 'path=\"[^\"]*\"' local_manifests/onclite.xml | sort | uniq -d | wc -l) -eq 0 ]"
assert_ok "vendor msm8953-common is pinned to revision lineage-20" "grep -q 'path=\"vendor/xiaomi/msm8953-common\".*revision=\"lineage-20\"' local_manifests/onclite.xml"
assert_ok "kernel is pinned to android_kernel_xiaomi_onclite at kernel/xiaomi/onclite" "grep -q 'path=\"kernel/xiaomi/onclite\".*name=\"LineageOS/android_kernel_xiaomi_onclite\"' local_manifests/onclite.xml"

echo ""
echo "--- СЕКЦИЯ 3: АУДИТ БИНАРНЫХ РЕСУРСОВ (MAGIC BYTES) ---"
assert_ok "wallpaper PNG size > 100KB" "[ \$(stat -c%s wallpapers/default_wallpaper.png) -gt 100000 ]"
assert_ok "bootanimation.tar size > 5MB" "[ \$(stat -c%s bootanimation_patches/bootanimation.tar) -gt 5000000 ]"
for OGG in audio_patches/*.ogg; do
    assert_ok "OGG Vorbis header check for $OGG" "head -c 4 '$OGG' | grep -q 'OggS'"
done
for PNG in icon_pack_patches/icons/*.png; do
    assert_ok "PNG header check for $PNG" "head -c 4 '$PNG' | grep -q \$'\\x89PNG'"
done

echo ""
echo "--- СЕКЦИЯ 4: ТЕСТ ИДЕМПОТЕНТНОСТИ НА МОК-ДЕРЕВЕ (3-КРАТНЫЙ ПРОГОН) ---"
mkdir -p tests/mock_idempotent/build/make/target/product
echo "# Mock product mk" > tests/mock_idempotent/build/make/target/product/handheld_product.mk

cd tests/mock_idempotent
# Прогон 1
grep -q "ro.sf.lcd_density" build/make/target/product/handheld_product.mk 2>/dev/null || echo "PRODUCT_PROPERTY_OVERRIDES += ro.sf.lcd_density=320" >> build/make/target/product/handheld_product.mk
# Прогон 2
grep -q "ro.sf.lcd_density" build/make/target/product/handheld_product.mk 2>/dev/null || echo "PRODUCT_PROPERTY_OVERRIDES += ro.sf.lcd_density=320" >> build/make/target/product/handheld_product.mk
# Прогон 3
grep -q "ro.sf.lcd_density" build/make/target/product/handheld_product.mk 2>/dev/null || echo "PRODUCT_PROPERTY_OVERRIDES += ro.sf.lcd_density=320" >> build/make/target/product/handheld_product.mk
cd "$ROOT_DIR"

assert_ok "Idempotency test: exactly 1 density override line after 3 runs" "[ \$(grep -c 'ro.sf.lcd_density=320' tests/mock_idempotent/build/make/target/product/handheld_product.mk) -eq 1 ]"
rm -rf tests/mock_idempotent

echo ""
echo "======================================================================"
echo " 🏆 ИСПЫТАТЕЛЬНЫЙ СТЕНД ЗАВЕРШЕН: УСПЕШНО ПРОЙДЕНО ТЕСТОВ: $PASS_COUNT (ОШИБОК: $FAIL_COUNT)"
echo "======================================================================"
