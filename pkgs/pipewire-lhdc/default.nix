# 带 LHDC v5 编码支持的 PipeWire。
#
# 上游 1.6.9 还没有 LHDC；master 上的 4 个提交（eee19d3..f300f59）以新增文件为主，
# 已压成 0001 补丁并验证可干净应用到 1.6.9。
# 这里只替换 NixOS 模块里 pipewire / wireplumber 用的那份，不覆盖全局 pkgs.pipewire，
# 避免把 kwin、firefox 等一大批依赖 pipewire 的包全部重编译。
{
  lib,
  pipewire,
  liblhdcv5,
}:

pipewire.overrideAttrs (old: {
  patches = (old.patches or [ ]) ++ [ ./0001-bluez5-add-lhdc-v5.patch ];

  buildInputs = (old.buildInputs or [ ]) ++ [ liblhdcv5 ];

  # 关掉文档构建省时间；对应的 doc 输出也要一并去掉，否则构建完没有这个产物。
  outputs = builtins.filter (output: output != "doc") (old.outputs or [ "out" ]);

  mesonFlags =
    builtins.filter (flag: flag != "-Ddocs=enabled") (old.mesonFlags or [ ])
    ++ [
      "-Ddocs=disabled"
      "-Dbluez5-codec-lhdc=enabled"
    ];

  # 上游测试不涉及 LHDC，跳过以缩短构建时间。
  doCheck = false;
})
