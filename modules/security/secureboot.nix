# Secure Boot：复用 Arch 上的 sbctl 密钥（/var/lib/sbctl/keys）
#
# 每次 grub-install 之后自动重签，否则 grub 升级会把引导器变成未签名状态，
# 下次重启直接进不了系统。
{ pkgs, ... }:

let
  signGrub = pkgs.writeShellScript "sign-grub" ''
    set -eu

    key=/var/lib/sbctl/keys/db/db.key
    cert=/var/lib/sbctl/keys/db/db.pem

    [ -f "$key" ] || { echo "sbctl 密钥不存在，跳过签名"; exit 0; }

    for f in /efi/EFI/nixos/grubx64.efi /efi/EFI/BOOT/BOOTX64.EFI; do
      [ -f "$f" ] || continue
      tmp="$f.signed"
      ${pkgs.sbsigntool}/bin/sbsign --key "$key" --cert "$cert" --output "$tmp" "$f"
      mv "$tmp" "$f"
      echo "signed: $f"
    done
  '';
in
{
  boot.loader.grub.extraInstallCommands = ''
    ${signGrub}
  '';

  # 兜底：开机再校验一次，防止某次 rebuild 漏签
  systemd.services.sign-grub = {
    description = "Re-sign GRUB EFI binary for Secure Boot";
    wantedBy = [ "multi-user.target" ];
    after = [ "local-fs.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = signGrub;
    };
  };
}
