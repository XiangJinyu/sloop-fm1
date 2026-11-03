#!/bin/sh
# SPDX-License-Identifier: GPL-3.0-only
# Fetch the tested Linux build dependencies without cloning the whole AC79 SDK.
# Usage: tools/ci_build_deps.sh [DEST]
# The archives and SDK files are verified before use; no firmware is installed.
set -eu

DEP_DIR="${1:-build/deps}"
mkdir -p "$DEP_DIR"
DEP_DIR="$(cd "$DEP_DIR" && pwd)"
TC_VERSION=jieli-linux-toolchains-20260730.1
TC_URL="https://jl-update.oss-cn-shenzhen.aliyuncs.com/$TC_VERSION.tar.xz"
TC_SHA=a1545cddbc451a06bac43eb5cd96d831470c42a97c5c0b1f98879a20fc7647bd
SDK_URL=https://gitee.com/Jieli-Tech/fw-AC79_AIoT_SDK/raw/AC79NN_SDK_V1.2.1_2023-12-13/cpu/wl82/tools
SDK_DIR="$DEP_DIR/ac79"

check_sha() {
    python3 - "$1" "$2" <<'PY'
import hashlib
import sys
from pathlib import Path
path, expected = Path(sys.argv[1]), sys.argv[2]
actual = hashlib.sha256(path.read_bytes()).hexdigest()
if actual != expected:
    raise SystemExit(f"dependency checksum mismatch: {path.name}: {actual}")
PY
}

fetch_checked() {
    fetch_url="$1"
    fetch_path="$2"
    fetch_sha="$3"
    mkdir -p "$(dirname "$fetch_path")"
    if [ -f "$fetch_path" ] && check_sha "$fetch_path" "$fetch_sha"; then
        return
    fi
    curl --fail --location --silent --show-error --retry 3 \
        --connect-timeout 20 --max-time 300 "$fetch_url" --output "$fetch_path.part"
    check_sha "$fetch_path.part" "$fetch_sha"
    mv "$fetch_path.part" "$fetch_path"
}

fetch_checked "$TC_URL" "$DEP_DIR/$TC_VERSION.tar.xz" "$TC_SHA"
tar -xJf "$DEP_DIR/$TC_VERSION.tar.xz" -C "$DEP_DIR"
[ -x "$DEP_DIR/$TC_VERSION/pi32v2/bin/clang" ] || {
    echo "toolchain archive has no pi32v2/bin/clang" >&2
    exit 1
}
fetch_checked "$SDK_URL/uboot.boot" "$SDK_DIR/cpu/wl82/tools/uboot.boot" \
    4e3b4c220dc96641cb5a723f41e68ce41d5261ae9434bb33fbd7f2c59976ded4
fetch_checked "$SDK_URL/cfg_tool.bin" "$SDK_DIR/cpu/wl82/tools/cfg_tool.bin" \
    276579954f076886a6a7694f65dc71c034a63a2c204b76749065c0ac7b010d1b
fetch_checked "$SDK_URL/cfg/eq_cfg_hw.bin" "$SDK_DIR/cpu/wl82/tools/cfg/eq_cfg_hw.bin" \
    41167491bffed4651750719c973d2758adeb9021a5670d02d6a53c85ed80ea7d

cat > "$DEP_DIR/manifest.txt" <<EOF
Toolchain: $TC_URL
SHA256: $TC_SHA
SDK: $SDK_URL
uboot.boot: 4e3b4c220dc96641cb5a723f41e68ce41d5261ae9434bb33fbd7f2c59976ded4
cfg_tool.bin: 276579954f076886a6a7694f65dc71c034a63a2c204b76749065c0ac7b010d1b
cfg/eq_cfg_hw.bin: 41167491bffed4651750719c973d2758adeb9021a5670d02d6a53c85ed80ea7d
EOF

if [ -n "${GITHUB_ENV:-}" ]; then
    printf 'JIELI_TOOLCHAIN=%s\nAC79_SDK=%s\n' \
        "$DEP_DIR/$TC_VERSION" "$SDK_DIR" >> "$GITHUB_ENV"
fi
printf 'JIELI_TOOLCHAIN=%s\nAC79_SDK=%s\n' "$DEP_DIR/$TC_VERSION" "$SDK_DIR"
echo "BUILD_DEPS_VERIFIED"
