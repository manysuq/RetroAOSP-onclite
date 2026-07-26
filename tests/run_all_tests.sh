#!/usr/bin/env bash
#
# RetroAOSP v2 — тестовый стенд.
# Проверяет то, что МОЖНО проверить без исходников Android:
#   синтаксис скриптов, валидность XML, целостность бинарных ассетов,
#   согласованность bootanimation (desc.txt <-> tar) и полный mock-прогон apply.sh.
# Соответствие целям апстрима lineage-21 проверяет CI (validate.yml) по живым исходникам.

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PASS=0; FAIL=0

ok()   { echo "  ✅ $1"; PASS=$((PASS+1)); }
bad()  { echo "  ❌ $1"; FAIL=$((FAIL+1)); }
check(){ local d="$1"; shift; if "$@" >/dev/null 2>&1; then ok "$d"; else bad "$d"; fi; }

echo "=== 1. Синтаксис shell-скриптов ==="
for f in "$ROOT/patches/apply.sh" "$ROOT/build_local.sh" "$ROOT/tests/run_all_tests.sh"; do
    check "bash -n $(basename "$f")" bash -n "$f"
done

echo "=== 2. Валидность XML (overlay + манифест) ==="
xml_ok() { python3 -c "import xml.etree.ElementTree as ET,sys; ET.parse(sys.argv[1])" "$1"; }
while IFS= read -r -d '' f; do
    check "XML: ${f#"$ROOT"/}" xml_ok "$f"
done < <(find "$ROOT/overlay" "$ROOT/local_manifests" -name "*.xml" -print0)

echo "=== 3. Гигиена файлов (CRLF / BOM) ==="
check "нет CRLF в скриптах и XML" bash -c "! grep -rlI \$'\r' '$ROOT/patches' '$ROOT/overlay' '$ROOT/tests' '$ROOT/build_local.sh'"
check "нет UTF-8 BOM" bash -c "! grep -rlI \$'\xef\xbb\xbf' '$ROOT/patches' '$ROOT/overlay'"

echo "=== 4. Целостность бинарных ассетов ==="
check "обои: PNG"            bash -c "head -c8 '$ROOT/overlay/frameworks/base/core/res/res/drawable-nodpi/default_wallpaper.png' | grep -q PNG"
for f in "$ROOT"/assets/icons/*.png; do
    check "иконка $(basename "$f"): PNG" bash -c "head -c8 '$f' | grep -q PNG"
done
for f in "$ROOT"/assets/sounds/*.ogg; do
    check "звук $(basename "$f"): OggS" bash -c "head -c4 '$f' | grep -q OggS"
done
check "bootanimation.tar читается" tar -tf "$ROOT/assets/bootanimation/bootanimation.tar"

echo "=== 5. Согласованность bootanimation: desc.txt <-> tar ==="
tar_parts=$(tar -tf "$ROOT/assets/bootanimation/bootanimation.tar" | cut -d/ -f1 | sort -u)
desc_parts=$(awk '{print $4}' "$ROOT/assets/bootanimation/desc.txt" | sort -u)
if [[ "$tar_parts" == "$desc_parts" ]]; then
    ok "части в desc.txt совпадают с каталогами в tar ($(echo "$tar_parts" | tr '\n' ' '))"
else
    bad "рассинхрон desc.txt и tar: [$desc_parts] vs [$tar_parts]"
fi

echo "=== 6. Mock-прогон apply.sh (строки-цели из реального lineage-21) ==="
MOCK=$(mktemp -d)
trap 'rm -rf "$MOCK"' EXIT
mkdir -p "$MOCK"/{frameworks/base/graphics/java/android/graphics/drawable,frameworks/base/packages/SystemUI/src/com/android/systemui/statusbar/phone,frameworks/base/data/sounds/effects/ogg,device/xiaomi/onclite,packages/apps/Trebuchet/src/com/android/launcher3/config,vendor/lineage/bootanimation,packages/apps/Settings/res/drawable}

cat > "$MOCK/frameworks/base/graphics/java/android/graphics/drawable/RippleDrawable.java" <<'EOF'
public class RippleDrawable {
    private static final boolean FORCE_PATTERNED_STYLE = true;
}
EOF
cat > "$MOCK/frameworks/base/packages/SystemUI/src/com/android/systemui/statusbar/phone/ClockController.java" <<'EOF'
public class ClockController {
    void init() {
        mActiveClock = mLeftClock;
        mClockPosition = LineageSettings.System.getInt(resolver,
                LineageSettings.System.STATUS_BAR_CLOCK, CLOCK_POSITION_LEFT);
    }
}
EOF
cat > "$MOCK/packages/apps/Trebuchet/src/com/android/launcher3/config/FeatureFlags.java" <<'EOF'
public final class FeatureFlags {
    public static final BooleanFlag ENABLE_ALL_APPS_BUTTON_IN_HOTSEAT = getDebugFlag(270393897,
            "ENABLE_ALL_APPS_BUTTON_IN_HOTSEAT", DISABLED,
            "Enables displaying the all apps button in the hotseat.");
}
EOF
cat > "$MOCK/device/xiaomi/onclite/device.mk" <<'EOF'
# Overlays
DEVICE_PACKAGE_OVERLAYS += $(LOCAL_PATH)/overlay
DEVICE_PACKAGE_OVERLAYS += $(LOCAL_PATH)/overlay-lineage
EOF
cat > "$MOCK/packages/apps/Settings/AndroidManifest.xml" <<'EOF'
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application android:icon="@drawable/ic_launcher_settings"/>
</manifest>
EOF
echo '<vector/>' > "$MOCK/packages/apps/Settings/res/drawable/ic_launcher_settings.xml"

run_apply() { (cd "$MOCK" && bash "$ROOT/patches/apply.sh"); }
check "apply.sh отработал на mock-дереве" run_apply
check "ripple: FORCE_PATTERNED_STYLE = false" grep -q "FORCE_PATTERNED_STYLE = false;" "$MOCK/frameworks/base/graphics/java/android/graphics/drawable/RippleDrawable.java"
check "часы: дефолт CLOCK_POSITION_RIGHT" grep -q "CLOCK_POSITION_RIGHT)" "$MOCK/frameworks/base/packages/SystemUI/src/com/android/systemui/statusbar/phone/ClockController.java"
check "launcher: флаг ENABLED" grep -q '"ENABLE_ALL_APPS_BUTTON_IN_HOTSEAT", ENABLED,' "$MOCK/packages/apps/Trebuchet/src/com/android/launcher3/config/FeatureFlags.java"
check "device.mk: overlay-retro подключён" grep -q 'overlay-retro' "$MOCK/device/xiaomi/onclite/device.mk"
check "overlay скопирован" test -f "$MOCK/device/xiaomi/onclite/overlay-retro/frameworks/base/core/res/res/values/config.xml"
check "bootanimation: tar + desc.txt" bash -c "test -s '$MOCK/vendor/lineage/bootanimation/bootanimation.tar' && grep -q part4 '$MOCK/vendor/lineage/bootanimation/desc.txt'"
check "звуки установлены" test -f "$MOCK/frameworks/base/data/sounds/effects/ogg/Lock.ogg"
check "иконка Settings: старый vector удалён" bash -c "! test -e '$MOCK/packages/apps/Settings/res/drawable/ic_launcher_settings.xml'"
check "иконка Settings: PNG на месте" test -f "$MOCK/packages/apps/Settings/res/drawable-xxxhdpi/ic_launcher_settings.png"
check "apply.sh идемпотентен (повторный прогон)" run_apply
check "device.mk: overlay-retro ровно один раз" bash -c "[ \$(grep -c overlay-retro '$MOCK/device/xiaomi/onclite/device.mk') -eq 1 ]"

echo
echo "=================================================="
echo " Итог: PASS=$PASS FAIL=$FAIL"
echo "=================================================="
[[ $FAIL -eq 0 ]]
