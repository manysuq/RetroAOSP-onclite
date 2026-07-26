#!/usr/bin/env bash
#
# RetroAOSP (NougatMod OS) — локальная сборка LineageOS 22.2 (Android 15) + ретро-патчи для Redmi 7 (onclite).
#
# Заточен под машину с небольшим свободным местом на системном диске:
# всё дерево исходников и сборка живут внутри sparse-файла с btrfs (сжатие zstd),
# лежащего на любом диске (включая NTFS/USB). После сборки файл просто удаляется.
#
# Использование:
#   ./build_local.sh all                # полный цикл: prepare -> sync -> patch -> build
#   ./build_local.sh prepare            # создать/примонтировать сборочный том + swap
#   ./build_local.sh sync               # repo init + repo sync (~100 ГБ трафика)
#   ./build_local.sh patch              # применить ретро-патчи
#   ./build_local.sh build              # компиляция (mka bacon), ~6-9 часов
#   ./build_local.sh build --reclaim    # перед сборкой удалить .repo (+50 ГБ места)
#   ./build_local.sh status             # что примонтировано и сколько места
#   ./build_local.sh destroy            # размонтировать и удалить образ (вернуть место)
#
# Все параметры можно переопределить через окружение, например:
#   IMG=/mnt/other/rom.img IMG_SIZE=300G ./build_local.sh prepare

set -euo pipefail

RETRO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

IMG="${IMG:-/run/media/mnsq/Data/retroaosp-build.img}"
IMG_SIZE="${IMG_SIZE:-250G}"
MNT="${MNT:-/mnt/retroaosp}"
ROM="$MNT/rom"
SWAPFILE="${SWAPFILE:-/swapfile-retroaosp}"   # на корневом btrfs, 12 ГБ, удаляется в destroy
SWAP_SIZE="${SWAP_SIZE:-12g}"
JOBS="${JOBS:-10}"                            # 12 потоков CPU, 2 оставляем системе
SYNC_JOBS="${SYNC_JOBS:-8}"
BUILD_TYPE="${BUILD_TYPE:-userdebug}"

die()  { echo "❌ $*" >&2; exit 1; }
step() { echo; echo "==> $*"; }

need_tools() {
    local missing=()
    for t in "$@"; do command -v "$t" >/dev/null || missing+=("$t"); done
    ((${#missing[@]})) && die "не хватает утилит: ${missing[*]} (sudo pacman -S --needed git git-lfs python curl btrfs-progs zip rsync)"
    return 0
}

ensure_repo_tool() {
    if ! command -v repo >/dev/null; then
        step "Устанавливаю утилиту repo в ~/.local/bin"
        mkdir -p "$HOME/.local/bin"
        curl -fsSL https://storage.googleapis.com/git-repo-downloads/repo -o "$HOME/.local/bin/repo"
        chmod +x "$HOME/.local/bin/repo"
        export PATH="$HOME/.local/bin:$PATH"
    fi
}

cmd_prepare() {
    need_tools git curl python3 mkfs.btrfs sudo truncate
    step "Сборочный том: $IMG ($IMG_SIZE, btrfs + zstd)"

    local img_dir; img_dir="$(dirname "$IMG")"
    [[ -d "$img_dir" ]] || die "каталог $img_dir не существует (диск не примонтирован?)"

    if [[ ! -f "$IMG" ]]; then
        local free_gb
        free_gb=$(df -BG --output=avail "$img_dir" | tail -1 | tr -dc '0-9')
        (( free_gb >= 170 )) || die "на $img_dir свободно ${free_gb}G — нужно минимум 170G (реально займётся ~120-150G благодаря сжатию)"
        truncate -s "$IMG_SIZE" "$IMG"
        mkfs.btrfs -q -f -L retroaosp "$IMG"
        echo "  создан sparse-образ (место занимается только по мере записи)"
    fi

    sudo mkdir -p "$MNT"
    if ! mountpoint -q "$MNT"; then
        sudo mount -o loop,compress-force=zstd:1,noatime "$IMG" "$MNT"
        sudo chown "$USER:$USER" "$MNT"
    fi
    mkdir -p "$ROM"
    echo "  примонтирован: $MNT"

    # swap: пики линковки/metalava на 16 ГБ RAM требуют подстраховки
    if ! swapon --show=NAME --noheadings | grep -q "$SWAPFILE"; then
        step "Swap-файл $SWAPFILE ($SWAP_SIZE)"
        if [[ ! -f "$SWAPFILE" ]]; then
            sudo btrfs filesystem mkswapfile --size "$SWAP_SIZE" "$SWAPFILE" 2>/dev/null \
                || { sudo touch "$SWAPFILE"; sudo chattr +C "$SWAPFILE"; \
                     sudo dd if=/dev/zero of="$SWAPFILE" bs=1M count=$(( ${SWAP_SIZE%g} * 1024 )) status=progress; \
                     sudo chmod 600 "$SWAPFILE"; sudo mkswap "$SWAPFILE"; }
        fi
        sudo swapon "$SWAPFILE"
    fi
    free -h | sed 's/^/  /'
    echo "✅ prepare завершён"
}

cmd_sync() {
    mountpoint -q "$MNT" || die "том не примонтирован — сначала ./build_local.sh prepare"
    ensure_repo_tool
    need_tools git git-lfs python3
    cd "$ROM"

    step "repo init (LineageOS 22.2 / Android 15 — последняя ветка с деревьями onclite)"
    repo init -u https://github.com/LineageOS/android.git -b lineage-22.2 --git-lfs --depth=1

    step "Локальный манифест Redmi 7 (onclite)"
    mkdir -p .repo/local_manifests
    cp -v "$RETRO_DIR/local_manifests/onclite.xml" .repo/local_manifests/onclite.xml

    step "repo sync (-j$SYNC_JOBS, ~100 ГБ трафика; при обрыве перезапускается до 3 раз)"
    local try
    for try in 1 2 3; do
        repo sync -c -j"$SYNC_JOBS" --force-sync --no-clone-bundle --no-tags --optimized-fetch --prune && break
        echo "⚠️ repo sync упал (попытка $try/3), повтор через 30 c..."; sleep 30
        [[ $try == 3 ]] && die "repo sync не прошёл за 3 попытки"
    done
    df -h "$MNT" | sed 's/^/  /'
    echo "✅ sync завершён"
}

cmd_patch() {
    mountpoint -q "$MNT" || die "том не примонтирован"
    cd "$ROM"
    bash "$RETRO_DIR/patches/apply.sh"
}

cmd_build() {
    mountpoint -q "$MNT" || die "том не примонтирован"
    cd "$ROM"
    [[ -f build/envsetup.sh ]] || die "исходники не синхронизированы"

    if [[ "${1:-}" == "--reclaim" ]]; then
        step "Удаляю .repo для освобождения ~50 ГБ (пересинк потребует sync заново!)"
        rm -rf .repo
    fi

    step "Компиляция lineage_onclite-$BUILD_TYPE (-j$JOBS). Это займёт 6-9 часов."
    df -h "$MNT" | sed 's/^/  /'
    export LC_ALL=C
    # shellcheck disable=SC1091
    source build/envsetup.sh
    lunch "lineage_onclite-$BUILD_TYPE"
    mka bacon -j"$JOBS"

    step "Результат"
    local zip
    zip=$(ls -t out/target/product/onclite/lineage-*-onclite*.zip 2>/dev/null | head -1) \
        || die "ZIP не найден — сборка не дошла до bacon"
    sha256sum "$zip"
    local dest_dir; dest_dir="$(dirname "$IMG")/RetroAOSP-out"
    mkdir -p "$dest_dir"
    cp -v "$zip" out/target/product/onclite/recovery.img "$dest_dir/" 2>/dev/null || cp -v "$zip" "$dest_dir/"
    echo "✅ Прошивка скопирована в $dest_dir — можно делать destroy и прошивать"
}

cmd_status() {
    echo "Образ: $IMG"
    [[ -f "$IMG" ]] && du -h --apparent-size "$IMG" | sed 's/^/  логический размер: /' && du -h "$IMG" | sed 's/^/  занято реально:   /'
    mountpoint -q "$MNT" && df -h "$MNT" | sed 's/^/  /' || echo "  не примонтирован"
    swapon --show | sed 's/^/  /' || true
}

cmd_destroy() {
    step "Размонтирование и удаление сборочного тома"
    mountpoint -q "$MNT" && sudo umount "$MNT"
    if swapon --show=NAME --noheadings | grep -q "$SWAPFILE"; then
        sudo swapoff "$SWAPFILE"
    fi
    sudo rm -f "$SWAPFILE"
    rm -f "$IMG"
    echo "✅ Место возвращено. Прошивка (если собрана) — в $(dirname "$IMG")/RetroAOSP-out"
}

case "${1:-help}" in
    prepare) cmd_prepare ;;
    sync)    cmd_sync ;;
    patch)   cmd_patch ;;
    build)   shift; cmd_build "$@" ;;
    all)     cmd_prepare; cmd_sync; cmd_patch; cmd_build --reclaim ;;
    status)  cmd_status ;;
    destroy) cmd_destroy ;;
    *) grep '^#' "$0" | head -25 | sed 's/^# \?//' ;;
esac
