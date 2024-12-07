{
  name,
  description ? "",
  hashedPassword,
  shell ? pkgs: pkgs.bashInteractive,
  canSudo ? false,
  canTTY ? false,
  systemUser ? false,
  packages ? [],
  home,
  groups ? [],
  uid,
  extraConfig ? {},
  extraHomeConfig ? {},
  homeStateVersion
}: {
  config = {
    users.users.${name} = {
      isNormalUser = !systemUser;
      extraGroups = groups ++ (if canSudo then ["wheel"] else []) ++ (if canTTY then ["tty"] else []);

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

