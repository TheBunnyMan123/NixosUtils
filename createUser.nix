{
  name,
  description ? "",
  hashedPassword,
  shell ? pkgs: pkgs.bashInteractive,
  canSudo ? false,
  canTTY ? false,
  canViewJournal ? canSudo,
  systemUser ? false,
  packages ? [],
  home,
  groups ? [],
  uid,
  extraConfig ? {},
  extraHomeConfig ? {},
  homeStateVersion
}: {
   lib,
   ...
}: {
  config = {
    users.users.${name} = {
      isNormalUser = !systemUser;
      extraGroups = groups
      ++ lib.optional canSudo "wheel"
      ++ lib.optional canTTY "tty"
      ++ lib.optional canViewJournal "systemd-journal";

      inherit home;
      inherit description;
      inherit packages;
      inherit hashedPassword;
      inherit shell;
      inherit uid;
    } // extraConfig;

    home-manager.users.${name} = {
      imports = [extraHomeConfig];
      config.home.stateVersion = homeStateVersion;
    };
  };
}

