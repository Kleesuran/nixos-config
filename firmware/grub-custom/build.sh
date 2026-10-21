#!/usr/bin/env bash
# 重新生成 core.efi：stock GRUB 2.14 + 本目录里打过补丁的 acpi.mod
#
# 用法（在仓库根目录）：
#   nix shell nixpkgs#grub2 -c ./firmware/grub-custom/build.sh
#
# 补丁点：acpi.mod 用 grub_register_extcmd 代替 grub_register_extcmd_lockdown，
# 使 Secure Boot/lockdown 下 `acpi /dsdt.aml` 仍可执行。
set -euo pipefail

here=$(cd "$(dirname "$0")" && pwd)
grub_mkimage=${GRUB_MKIMAGE:-$(command -v grub-mkimage)}
grub_prefix=$(dirname "$(dirname "$(readlink -f "$grub_mkimage")")")
mods_src="$grub_prefix/lib/grub/x86_64-efi"

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

cp -r "$mods_src" "$tmp/mods"
chmod -R u+w "$tmp/mods"
install -m644 "$here/acpi.mod" "$tmp/mods/acpi.mod"

cat > "$tmp/early.cfg" <<'EOF'
search --no-floppy --fs-uuid --set=root 724b4e5f-3e76-4ac0-8ed7-ea74201deee2
set prefix=($root)/@boot/grub
configfile ($root)/@boot/grub/grub.cfg
EOF

mods=(
  normal tpm linux boot btrfs part_gpt fat acpi chain configfile loadenv
  search search_fs_uuid search_label test echo font gfxterm png efi_gop
  efi_uga all_video gfxmenu gfxterm_background minicmd ext2 xfs ntfs zstd
  efifwsetup halt reboot sleep gettext
)

"$grub_mkimage" -O x86_64-efi -d "$tmp/mods" -p '/@boot/grub' \
  -c "$tmp/early.cfg" --disable-shim-lock \
  -o "$tmp/core.efi" "${mods[@]}"

install -m644 "$tmp/core.efi" "$here/core.efi"
printf 'built %s\n' "$here/core.efi"
sha256sum "$here/core.efi"
