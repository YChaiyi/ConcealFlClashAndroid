#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
module_dir="$repo_root/sukisu-module"
out_dir="$repo_root/build/root-module"
out_zip="$out_dir/conceal-flclash-tun-helper.zip"
binary_dir="$module_dir/bin"
binary_path="$binary_dir/conceal-flclash-mihomo-arm64"
root_tun_patch="$module_dir/patches/mihomo-root-tun.patch"
mihomo_src="$out_dir/mihomo-src"

mkdir -p "$out_dir"
rm -f "$out_zip"
mkdir -p "$binary_dir"
rm -rf "$mihomo_src"
mkdir -p "$mihomo_src"

(git -C "$repo_root/core/Clash.Meta" archive HEAD | tar -x -C "$mihomo_src")
(cd "$mihomo_src" && patch -p1 < "$root_tun_patch" >/dev/null)
(cd "$mihomo_src" && \
  env GOOS=android GOARCH=arm64 CGO_ENABLED=0 \
    go build -tags with_gvisor -trimpath -ldflags='-s -w' -o "$binary_path" .)
chmod 0755 "$binary_path"

(cd "$module_dir" && zip -r "$out_zip" . -x '*.DS_Store' 'flclash-root.log' 'run/*' 'patches/*' >/dev/null)

echo "$out_zip"
