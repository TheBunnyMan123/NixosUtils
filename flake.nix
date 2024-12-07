{
   description = "Flake for NixOS";

   inputs = rec {
      nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
      home-manager.url = "github:nix-community/home-manager";
      home-manager.inputs.nixpkgs.follows = "nixpkgs";
      flake-utils.url = "github:numtide/flake-utils";
   };

   outputs = { nixpkgs, flake-utils, ... }: (flake-utils.lib.eachDefaultSystem (system: let
      lib = nixpkgs."${system}".legacyPackages.lib;
   in {
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
         createUser = import ./createUser.nix;
      };
   }));
}
