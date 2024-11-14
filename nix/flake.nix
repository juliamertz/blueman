{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
  };
  outputs =
    { nixpkgs, flake-parts, ... }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = nixpkgs.lib.systems.flakeExposed;

      perSystem =
        { pkgs, ... }:
        {
          # packages.default = pkgs.callPackage ./package.nix { };
          packages.default =
            with pkgs;
            let
              pythonPackages = python3Packages;
            in
            stdenv.mkDerivation rec {
              pname = "blueman";
              version = "2.4.3";

              src = ../.;

              nativeBuildInputs = [
                gobject-introspection
                intltool
                pkg-config
                pythonPackages.cython
                pythonPackages.wrapPython
                wrapGAppsHook3
              ];

              buildInputs = [
                bluez
                gtk3
                pythonPackages.python
                librsvg
                adwaita-icon-theme
                networkmanager
                autoconf
                automake
                libtool
                nettools
              ] ++ pythonPath;

              pythonPath = with pythonPackages; [
                pygobject3
                pycairo
              ];

              buildPhase = ''
                ./autogen.sh
              '';

              propagatedUserEnvPkgs = [ obex_data_server ];

              configureFlags = [
                "--with-systemdsystemunitdir=${placeholder "out"}/lib/systemd/system"
                "--with-systemduserunitdir=${placeholder "out"}/lib/systemd/user"
                # Don't check for runtime dependency `ip` during the configure
                "--disable-runtime-deps-check"
              ];

              makeWrapperArgs = [
                "--prefix PATH ':' ${
                  lib.makeBinPath [
                    dnsmasq
                    dhcpcd
                    iproute2
                  ]
                }"
                "--suffix PATH ':' ${lib.makeBinPath [ xdg-utils ]}"
              ];

              postFixup = ''
                # This mimics ../../../development/interpreters/python/wrap.sh
                wrapPythonProgramsIn "$out/bin" "$out $pythonPath"
                wrapPythonProgramsIn "$out/libexec" "$out $pythonPath"
              '';
            };
        };
    };
}
