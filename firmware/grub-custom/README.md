# 定制 GRUB core（NixOS 管理）

这个目录里的 `core.efi` 取代 NixOS 自带的 GRUB 核心，安装到
`/efi/EFI/NixOS-efi/grubx64.efi`（Boot0003），由 NixOS 在 activation 时签名。

## 为什么需要

NixOS/上游 GRUB 2.14 的 `acpi.mod` 用 `grub_register_extcmd_lockdown` 注册，
Secure Boot/lockdown 下 `acpi` 命令会被拒绝；Windows 就无法在 chainload 前
注入修好的 DSDT。

这里的 `acpi.mod` 是从原先 Arch 上那份定制 GRUB 里取出的，改用
`grub_register_extcmd` 注册。`core.efi` 是 stock GRUB 2.14 的模块 +
这个 `acpi.mod` 重新打包的（其余模块不变）。

## 内容

| 文件 | 说明 | SHA-256 |
| --- | --- | --- |
| `core.efi` | 未签名核心，1,146,880 字节 | `ae4643469bd605b2d4426b91416b76c554e351cafc9b99746713bfe13dfbd2ab` |
| `acpi.mod` | Arch 定制版，16,888 字节 | `52c0fc8599800624a6732c7c1d916dd4213c6b053f4a5681582d948d29f8287d` |
| `build.sh` | 从 nixpkgs 的 GRUB 2.14 重新打包 | — |

内嵌 early config：

```
search --no-floppy --fs-uuid --set=root 724b4e5f-3e76-4ac0-8ed7-ea74201deee2
set prefix=($root)/@boot/grub
configfile ($root)/@boot/grub/grub.cfg
```

因此它只依赖 NixOS 的 `@boot` 子卷，不再经过 Arch 的 `@/boot/grub`。

## 重建

```bash
nix shell nixpkgs#grub2 -c ./firmware/grub-custom/build.sh
```

## 校验

```bash
grub-file --is-x86_64-efi firmware/grub-custom/core.efi
strings -a firmware/grub-custom/core.efi | grep -A3 'search --no-floppy'
# core 里 grub_register_extcmd_lockdown 的出现次数应比 stock core 少 1
```
