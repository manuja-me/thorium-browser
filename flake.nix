{
  description = "Thorium Browser - A Chromium fork focused on speed and security";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };

        thorium-version = "119.0.6045.159";
        thorium-channel = "x64";

        thorium-browser = pkgs.stdenv.mkDerivation rec {
          pname = "thorium-browser";
          version = thorium-version;

          src = pkgs.fetchurl {
            url = "https://github.com/Alex313031/thorium/releases/download/M${thorium-version}/thorium-browser_${thorium-version}_${thorium-channel}.deb";
            sha256 = "sha256-xyVis7Zww8H28GRUDX6LR9txP74h/2w%2BqVBXrCsHnFQ%3D";
          };

          nativeBuildInputs = [ 
            pkgs.dpkg 
            pkgs.wrapGAppsHook 
            pkgs.makeWrapper
          ];

          buildInputs = with pkgs; [
            # System libraries
            stdenv.cc.cc.lib
            alsa-lib
            at-spi2-atk
            at-spi2-core
            atk
            cairo
            cups
            curl
            dbus
            expat
            fontconfig
            freetype
            gdk-pixbuf
            glib
            gtk3
            libX11
            libXScrnSaver
            libXcomposite
            libXcursor
            libXdamage
            libXext
            libXfixes
            libXi
            libXrandr
            libXrender
            libXtst
            libdrm
            libnotify
            libopus
            libpulseaudio
            libuuid
            libxcb
            libxkbcommon
            libxshmfence
            mesa
            nspr
            nss
            pango
            systemd
            udev
            xorg.libxcb
            xorg.libXScrnSaver
            zlib

            # Additional dependencies for better compatibility
            xdg-utils
            xorg.libxshmfence
            util-linux
            pulseaudio
            ffmpeg
            libva
            pipewire
          ];

          unpackPhase = ''
            runHook preUnpack
            mkdir -p $out
            dpkg -x $src $out
            sourceRoot=$out
            runHook postUnpack
          '';

          installPhase = ''
            runHook preInstall

            # Fix path in desktop file
            mkdir -p $out/share/applications
            cp $out/usr/share/applications/thorium-browser.desktop $out/share/applications/
            substituteInPlace $out/share/applications/thorium-browser.desktop \
              --replace /opt/chromium.org/thorium $out/opt/chromium.org/thorium \
              --replace "Exec=/opt/chromium.org/thorium/thorium-browser" "Exec=thorium-browser"

            # Copy icons
            mkdir -p $out/share/icons
            cp -r $out/usr/share/icons/* $out/share/icons/

            # Create bin directory if it doesn't exist
            mkdir -p $out/bin

            runHook postInstall
          '';

          postFixup = ''
            # Create wrapper for thorium-browser with proper environment
            makeWrapper $out/opt/chromium.org/thorium/thorium-browser $out/bin/thorium-browser \
              --prefix LD_LIBRARY_PATH : ${pkgs.lib.makeLibraryPath buildInputs} \
              --prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.xdg-utils ]} \
              --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations}}" \
              --add-flags "--disable-features=UseChromeOSDirectVideoDecoder"

            # Create wrapper for thorium-shell with proper environment
            makeWrapper $out/opt/chromium.org/thorium/thorium-shell $out/bin/thorium-shell \
              --prefix LD_LIBRARY_PATH : ${pkgs.lib.makeLibraryPath buildInputs} \
              --prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.xdg-utils ]} \
              --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations}}" \
              --add-flags "--disable-features=UseChromeOSDirectVideoDecoder"

            # Fix dynamic linker and RPATH for binaries
            for binary in $out/opt/chromium.org/thorium/thorium-browser $out/opt/chromium.org/thorium/thorium-shell; do
              patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" "$binary"
              
              # Add RPATH for better compatibility with NixOS libraries
              patchelf --set-rpath "${pkgs.lib.makeLibraryPath buildInputs}" "$binary"
            done
          '';

          meta = with pkgs.lib; {
            description = "Thorium Browser - Chromium fork focused on speed and security";
            homepage = "https://thorium.rocks/";
            license = licenses.bsd3;
            platforms = [ "x86_64-linux" ];
            maintainers = with maintainers; [ ];
          };
        };
      in
      {
        packages = {
          thorium-browser = thorium-browser;
          default = thorium-browser;
        };

        apps.default = flake-utils.lib.mkApp {
          drv = thorium-browser;
          name = "thorium-browser";
        };
      });
}
