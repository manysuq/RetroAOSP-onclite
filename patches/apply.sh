#!/usr/bin/env bash
#
# RetroAOSP (NougatMod OS) — интегратор ретро-патчей для LineageOS 21 (Android 14).
# Запускать из корня исходников ROM: bash /path/to/RetroAOSP-onclite/patches/apply.sh
#
# Принципы (в отличие от v1.x):
#   1. Ресурсы переопределяются через DEVICE_PACKAGE_OVERLAYS (легальные оверлеи),
#      а не копированием файлов-дубликатов в res/values (это роняло aapt2).
#   2. Каждый Java-патч проверяется: если целевая строка не найдена и результат
#      ещё не применён — скрипт ПАДАЕТ, а не молча продолжает.
#   3. Все целевые строки сверены с реальными исходниками lineage-21 (июль 2026).

set -euo pipefail

RETRO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WARNINGS=()

log()  { echo "  $*"; }
step() { echo; echo "==> $*"; }
die()  { echo "❌ ОШИБКА: $*" >&2; exit 1; }
warn() { echo "⚠️  $*"; WARNINGS+=("$*"); }

# Замена фиксированной строки FROM -> TO в файле.
# Идемпотентно: если FROM нет, но TO уже есть — считается применённым.
# mode=must: отсутствие и FROM, и TO — фатальная ошибка.
replace_in_file() {
    local mode="$1" file="$2" from="$3" to="$4" desc="$5"
    if [[ ! -f "$file" ]]; then
        [[ "$mode" == "must" ]] && die "$desc: файл не найден: $file"
        warn "$desc: файл не найден: $file — пропуск"
        return 0
    fi
    local result
    result=$(python3 - "$file" "$from" "$to" <<'PYEOF'
import sys
path, src, dst = sys.argv[1], sys.argv[2], sys.argv[3]
text = open(path, encoding="utf-8").read()
if src in text:
    open(path, "w", encoding="utf-8").write(text.replace(src, dst))
    print(f"PATCHED:{text.count(src)}")
elif dst in text:
    print("ALREADY")
else:
    print("NOTFOUND")
PYEOF
)
    case "$result" in
        PATCHED:*) log "✔ $desc (замен: ${result#PATCHED:})" ;;
        ALREADY)   log "✔ $desc (уже применён)" ;;
        NOTFOUND)
            if [[ "$mode" == "must" ]]; then
                die "$desc: целевая строка не найдена в $file — исходники изменились, патч требует обновления"
            else
                warn "$desc: целевая строка не найдена в $file — пропуск"
            fi ;;
    esac
}

# ---------------------------------------------------------------------------
echo "=============================================================="
echo " RetroAOSP v2 — применение ретро-патчей (Android 7 UI на LOS 21)"
echo "=============================================================="

[[ -d frameworks/base ]] || die "запускайте скрипт из корня исходников Android (не найдено frameworks/base)"
[[ -d device/xiaomi/onclite ]] || die "не найдено дерево устройства device/xiaomi/onclite (сначала repo sync)"

# ---------------------------------------------------------------------------
step "1/7: Установка ресурсного оверлея (DEVICE_PACKAGE_OVERLAYS)"

OVERLAY_DST="device/xiaomi/onclite/overlay-retro"
rm -rf "$OVERLAY_DST"
cp -r "$RETRO_DIR/overlay" "$OVERLAY_DST"
log "✔ оверлей скопирован в $OVERLAY_DST"

DEVICE_MK="device/xiaomi/onclite/device.mk"
[[ -f "$DEVICE_MK" ]] || die "не найден $DEVICE_MK"
if grep -q 'overlay-retro' "$DEVICE_MK"; then
    log "✔ device.mk уже подключает overlay-retro"
else
    grep -q 'DEVICE_PACKAGE_OVERLAYS' "$DEVICE_MK" \
        || die "в $DEVICE_MK не найдено DEVICE_PACKAGE_OVERLAYS — структура дерева изменилась"
    sed -i '0,/^DEVICE_PACKAGE_OVERLAYS/s//DEVICE_PACKAGE_OVERLAYS += $(LOCAL_PATH)\/overlay-retro\n&/' "$DEVICE_MK"
    grep -q 'overlay-retro' "$DEVICE_MK" || die "не удалось подключить overlay-retro в device.mk"
    log "✔ overlay-retro подключён в device.mk"
fi

# ---------------------------------------------------------------------------
step "2/7: Классическая волна касания (RippleDrawable: solid вместо patterned)"

replace_in_file must \
    "frameworks/base/graphics/java/android/graphics/drawable/RippleDrawable.java" \
    "private static final boolean FORCE_PATTERNED_STYLE = true;" \
    "private static final boolean FORCE_PATTERNED_STYLE = false;" \
    "RippleDrawable: чистая радиальная волна MD1 (без искр)"

# ---------------------------------------------------------------------------
step "3/7: Часы статус-бара справа по умолчанию (как в Android 7)"

CLOCK_CTRL="frameworks/base/packages/SystemUI/src/com/android/systemui/statusbar/phone/ClockController.java"
replace_in_file must "$CLOCK_CTRL" \
    "LineageSettings.System.STATUS_BAR_CLOCK, CLOCK_POSITION_LEFT)" \
    "LineageSettings.System.STATUS_BAR_CLOCK, CLOCK_POSITION_RIGHT)" \
    "ClockController: дефолтная позиция часов = RIGHT"
replace_in_file try "$CLOCK_CTRL" \
    "mActiveClock = mLeftClock;" \
    "mActiveClock = mRightClock;" \
    "ClockController: стартовый активный view = правые часы"

# ---------------------------------------------------------------------------
step "4/7: Кнопка «Все приложения» в доке лаунчера (Trebuchet)"

replace_in_file must \
    "packages/apps/Trebuchet/src/com/android/launcher3/config/FeatureFlags.java" \
    "\"ENABLE_ALL_APPS_BUTTON_IN_HOTSEAT\", DISABLED," \
    "\"ENABLE_ALL_APPS_BUTTON_IN_HOTSEAT\", ENABLED," \
    "Trebuchet: флаг ENABLE_ALL_APPS_BUTTON_IN_HOTSEAT включён"

# ---------------------------------------------------------------------------
step "5/7: Анимация загрузки CyanogenMod 14.1"

BOOTANIM_DIR="vendor/lineage/bootanimation"
[[ -d "$BOOTANIM_DIR" ]] || die "не найден $BOOTANIM_DIR (vendor/lineage не синхронизирован?)"
cp "$RETRO_DIR/assets/bootanimation/bootanimation.tar" "$BOOTANIM_DIR/bootanimation.tar"
# КРИТИЧНО: vendor-desc.txt описывает только part0-part2, а в архиве CM их пять.
# Без замены desc.txt анимация обрезается и неправильно зацикливается.
cp "$RETRO_DIR/assets/bootanimation/desc.txt" "$BOOTANIM_DIR/desc.txt"
log "✔ bootanimation.tar (part0..part4) + согласованный desc.txt установлены"

# ---------------------------------------------------------------------------
step "6/7: Классические системные звуки (Nougat: Tick / Lock / Unlock)"

SOUNDS_DIR="frameworks/base/data/sounds/effects"
[[ -d "$SOUNDS_DIR" ]] || die "не найден $SOUNDS_DIR"
for f in Effect_Tick.ogg Lock.ogg Unlock.ogg; do
    cp "$RETRO_DIR/assets/sounds/$f" "$SOUNDS_DIR/$f"
    [[ -d "$SOUNDS_DIR/ogg" ]] && cp "$RETRO_DIR/assets/sounds/$f" "$SOUNDS_DIR/ogg/$f"
done
log "✔ звуки заменены в $SOUNDS_DIR{,/ogg}"

# ---------------------------------------------------------------------------
step "7/7: Классические иконки системных приложений"

# Имя ресурса иконки берём из AndroidManifest.xml конкретного приложения,
# удаляем адаптивные anydpi-обёртки ТОЛЬКО этого ресурса и кладём PNG
# в 4 плотности. Никаких захардкоженных имён.
install_icon() {
    local app_dir="$1" png="$2"
    local manifest="$app_dir/AndroidManifest.xml"
    if [[ ! -f "$manifest" || ! -d "$app_dir/res" ]]; then
        warn "иконки: $app_dir отсутствует — пропуск"
        return 0
    fi
    local refs ref rtype rname
    refs=$(grep -oE 'android:(icon|roundIcon)="@(mipmap|drawable)/[A-Za-z0-9_]+"' "$manifest" \
            | sed -E 's/.*"@//; s/"//' | sort -u)
    if [[ -z "$refs" ]]; then
        warn "иконки: в $manifest не найдена ссылка на иконку — пропуск"
        return 0
    fi
    for ref in $refs; do
        rtype="${ref%%/*}" rname="${ref##*/}"
        # выпиливаем ВСЕ существующие варианты ресурса (webp/png/xml, включая anydpi-v26)
        find "$app_dir/res" -regextype posix-extended \
            -regex ".*/(${rtype}|${rtype}-[^/]+)/${rname}\.(png|webp|jpg|xml)" -delete
        for dpi in hdpi xhdpi xxhdpi xxxhdpi; do
            mkdir -p "$app_dir/res/${rtype}-${dpi}"
            cp "$png" "$app_dir/res/${rtype}-${dpi}/${rname}.png"
        done
        log "✔ $app_dir: @$rtype/$rname -> классический PNG"
    done
}

install_icon packages/apps/Settings        "$RETRO_DIR/assets/icons/settings.png"
install_icon packages/apps/DeskClock       "$RETRO_DIR/assets/icons/deskclock.png"
install_icon packages/apps/ExactCalculator "$RETRO_DIR/assets/icons/calculator.png"
install_icon packages/apps/Contacts        "$RETRO_DIR/assets/icons/contacts.png"
install_icon packages/apps/Dialer          "$RETRO_DIR/assets/icons/dialer.png"
install_icon packages/apps/DocumentsUI     "$RETRO_DIR/assets/icons/documentsui.png"

# ---------------------------------------------------------------------------
echo
echo "=============================================================="
if ((${#WARNINGS[@]})); then
    echo " Готово с предупреждениями (${#WARNINGS[@]}):"
    printf '   - %s\n' "${WARNINGS[@]}"
else
    echo " ✅ Все ретро-патчи применены без предупреждений."
fi
echo " Дальше: source build/envsetup.sh && lunch lineage_onclite-userdebug && mka bacon"
echo "=============================================================="
