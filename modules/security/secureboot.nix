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

    for f in /efi/EFI/NixOS*/grubx64.efi /efi/EFI/nixos*/grubx64.efi /efi/EFI/BOOT/BOOTX64.EFI; do
      [ -f "$f" ] || continue

      # 已由本密钥签过就跳过，避免反复追加签名
      if ${pkgs.sbsigntool}/bin/sbverify --cert "$cert" "$f" >/dev/null 2>&1; then
        echo "already signed: $f"
        continue
      fi

      tmp="$f.signed"
      ${pkgs.sbsigntool}/bin/sbsign --key "$key" --cert "$cert" --output "$tmp" "$f"
      ${pkgs.coreutils}/bin/mv "$tmp" "$f"
      echo "signed: $f"
    done
  '';

  # GRUB 2.14 通过 EFI LoadImage() 加载内核，Secure Boot 下内核也必须签名。
  # install-grub.pl 只在 /boot/kernels 目标不存在时才复制，因此内核升级后
  # 新增的 bzImage 需要在这里补签。
  signKernels = pkgs.writeShellScript "sign-kernels" ''
    set -eu

    key=/var/lib/sbctl/keys/db/db.key
    cert=/var/lib/sbctl/keys/db/db.pem

    [ -f "$key" ] || { echo "sbctl 密钥不存在，跳过内核签名"; exit 0; }

    for f in /boot/kernels/*-bzImage; do
      [ -f "$f" ] || continue

      if ${pkgs.sbsigntool}/bin/sbverify --cert "$cert" "$f" >/dev/null 2>&1; then
        continue
      fi

      ${pkgs.sbsigntool}/bin/sbsign --key "$key" --cert "$cert" \
        --output "$f.signed" "$f"
      ${pkgs.coreutils}/bin/mv "$f.signed" "$f"
      echo "signed kernel: $f"
    done
  '';
in
{
  boot.loader.grub.extraInstallCommands = ''
    ${signGrub}
    ${signKernels}
  '';

  # GRUB 的 Windows 条目从 ESP 根目录读取 acpi 表
  system.activationScripts.dsdt = {
    text = ''
      if [ -d /efi ]; then
        ${pkgs.coreutils}/bin/install -Dm644 ${../../firmware/dsdt.aml} /efi/dsdt.aml
      fi
    '';
  };

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

  systemd.services.sign-kernels = {
    description = "Re-sign kernels for Secure Boot";
    wantedBy = [ "multi-user.target" ];
    after = [ "local-fs.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = signKernels;
    };
  };
}
