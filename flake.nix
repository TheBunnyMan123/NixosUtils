{
   description = "Flake for NixOS";

   inputs = {
      nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
      home-manager.url = "github:nix-community/home-manager";
      home-manager.inputs.nixpkgs.follows = "nixpkgs";
      flake-utils.url = "github:numtide/flake-utils";
   };

   outputs = { nixpkgs, flake-utils, ... }: (flake-utils.lib.eachDefaultSystem (system: let
      lib = nixpkgs.lib;
      pkgs = nixpkgs.legacyPackages."${system}";
      
      user = rec {
         options = {
            name = lib.mkOption {
               type = lib.types.string;
               description = "The user's name";
               example = "root";
            };
            description = lib.mkOption {
               type = lib.types.string;
               description = "The user's description";
               example = "System Administrator";
            };
            hashedPassword = lib.mkOption {
               type = lib.types.string;
               description = "The user's password hash";
               example = "$y$j9T$VEJtLu77FdTIbtMenY.M90$SaIAHQtSuTnRJY7OqBzFkM7fPKMOyfctVeNADa8uHO4";
            };
            shell = lib.mkOption {
               type = lib.types.shellPackage;
               description = "The user's shell";
               example = pkgs.bashInteractive;
            };
            canSudo = lib.mkOption {
               type = lib.types.bool;
               description = "Whether the user should be a sudoer";
               example = true;
               default = false;
            };
            canTTY = lib.mkOption {
               type = lib.types.bool;
               description = "Whether the user should be able to write to tty devices";
               example = true;
               default = false;
            };
            canViewJournal = lib.mkOption {
               type = lib.types.bool;
               description = "Whether the user should be able to view the systemd journal";
               example = true;
               default = false;
            };
            systemUser = lib.mkOption {
               type = lib.types.bool;
               description = "Whether the user is a system user";
               example = true;
               default = false;
            };
            linger = lib.mkOption {
               type = lib.types.bool;
               description = "Whether the user's units should be started at boot";
               example = true;
               default = false;
            };
            packages = lib.mkOption {
               type = lib.types.attrsOf lib.types.package;
               description = "The user's packages";
               example = [ pkgs.neovim ];
               default = [ ];
            };
            home = lib.mkOption {
               type = lib.types.string;
               description = "The user's home directory";
               example = "/home/bunny";
               default = "/home/${options.name}";
            };
            groups = lib.mkOption {
               type = lib.types.attrsOf lib.types.string;
               description = "The user's groups";
               example = [ "docker" ];
               default = [ ];
            };
            uid = lib.mkOption {
               type = lib.types.ints.u16;
               description = "The user's UID";
               example = 1000;
            };
            extraConfig = lib.mkOption {
               type = lib.types.submodule;
               description = "Extra user config (users.users.<name>)";
               example = {};
               default = {};
            };
            extraHomeConfig = lib.mkOption {
               type = lib.types.submodule;
               description = "Home-manager config";
               example = {};
               default = {};
            };
            homeStateVersion = {
               type = lib.types.string;
               description = "The system's state version";
               example = "23.05";
            };
            shellInitFile = {
               type = lib.types.pathInStore;
               description = "The user's global shell init";
               example = "";
               default = pkgs.writeTextFile "exmpty-shell-init.sh" "";
            };
         };
      };
   in rec {
      nixosModules = {
         buildFirefoxAddon = lib.makeOverridable (
            {
               pkgs ? nixpkgs.legacyPackages."${system}" ,
               fetchFirefoxAddon ? pkgs.fetchFirefoxAddon,
               stdenv ? pkgs.stdenv,
               name,
               version,
               url,
               hash,
               fixedExtid ? null,
               ...
            }: let
               extid = if fixedExtid == null then "nixos@${name}" else fixedExtid;
            in stdenv.mkDerivation {
               inherit name version;

               src = fetchFirefoxAddon { inherit url hash name; fixedExtid = extid; };

               preferLocalBuild = true;
               allowSubstitutes = true;

               buildCommand = ''
                  dist="$out/share/mozilla/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}"
                  mkdir -p "$dist"
                  ls $src
                  install -v -m644 "$src/${extid}.xpi" "$dist/${extid}.xpi"
               '';
            }
         );
         createUser = userConfig: (let
            cfg = (pkgs.evalModules [userConfig user]);
         in {
            config,
            pkgs,
            ...
         }: {
            config = {
               users.users."${cfg.name}" = {
                  isNormalUser = !cfg.systemUser;
                  inherit (cfg) home description packages hashedPassword shell uid linger;
               } // cfg.extraConfig;

               environment.shellInit = ''
                  if [[ "${cfg.uid}" -eq "$(${pkgs.coreutils}/bin/id -u)" ]]
                  then
                     source "${cfg.shellInitFile}"
                  fi
               '';

               home-manager.users."${cfg.name}" = {
                  imports = [ cfg.extraHomeConfig ];
                  home.stateVersion = cfg.homeStateVersion;
               };
            };
         });
      };
   }));
}
