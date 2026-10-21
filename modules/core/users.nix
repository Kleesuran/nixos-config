# 用户与提权
{ pkgs, ... }:

{
  users.groups.uinput = { };

  users.users.klee = {
    isNormalUser = true;
    uid = 1000;
    description = "Klee";
    shell = pkgs.bash;
    extraGroups = [
      "wheel"
      "networkmanager"
      "video"
      "render"
      "audio"
      "input"
      "kvm"
      "uinput"
      "plugdev"
    ];
  };

  security.sudo.wheelNeedsPassword = true;
}
