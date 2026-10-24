# AMD Ryzen 7 3700X（Zen2）
{ ... }:

{
  boot.kernelParams = [
    "amd_pstate=active"
    "amd_iommu=on"
    "iommu=pt"
  ];
}
