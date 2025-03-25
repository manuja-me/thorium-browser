# Thorium Browser Nix Flake

A Nix flake package for [Thorium Browser](https://thorium.rocks/) - a Chromium fork focused on speed, security, and maximum performance.

## Features

- **Optimized for NixOS**: Properly packaged with all dependencies to work seamlessly in the pure Nix environment
- **Wayland Support**: Configured with proper Wayland integration, including window decorations
- **Hardware Acceleration**: Support for VA-API and hardware video decoding
- **Comprehensive Dependencies**: All necessary libraries included to avoid common Chromium-related issues
- **Modern Packaging**: Uses Nix flakes for reproducible builds

## Installation

### As a Standalone Package

```bash
# Clone the repository
git clone https://github.com/yourusername/thorium-browser-nix.git
cd thorium-browser-nix

# Install directly
nix profile install .

# Or run without installing
nix run .
```

### Integrating with Your NixOS Configuration

Add this flake to your main flake's inputs:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    
    # Thorium Browser
    thorium-browser = {
      url = "path:/path/to/thorium-browser";  # Local path
      # Or use a git repository
      # url = "github:yourusername/thorium-browser-nix";
    };
  };
  
  outputs = { self, nixpkgs, thorium-browser, ... }: {
    # NixOS configuration
    nixosConfigurations.yourhostname = nixpkgs.lib.nixosSystem {
      # ...existing configuration...
      modules = [
        # ...your other modules...
        
        # Make Thorium Browser available system-wide
        ({ pkgs, ... }: {
          environment.systemPackages = [
            thorium-browser.packages.x86_64-linux.default
          ];
        })
      ];
    };
    
    # Home Manager configuration
    homeConfigurations.yourusername = home-manager.lib.homeManagerConfiguration {
      # ...existing configuration...
      modules = [
        # ...your other modules...
        
        # Add Thorium to home environment and set as default browser
        ({ pkgs, ... }: {
          home.packages = [
            thorium-browser.packages.x86_64-linux.default
          ];
          
          # Set as default browser
          xdg.mimeApps = {
            enable = true;
            defaultApplications = {
              "text/html" = "thorium-browser.desktop";
              "x-scheme-handler/http" = "thorium-browser.desktop";
              "x-scheme-handler/https" = "thorium-browser.desktop";
              "x-scheme-handler/about" = "thorium-browser.desktop";
              "x-scheme-handler/unknown" = "thorium-browser.desktop";
            };
          };
        })
      ];
    };
  };
}
```

## Configuration

### Updating the Browser Version

To update the Thorium Browser version, modify these variables in `flake.nix`:

```nix
thorium-version = "119.0.6045.159"; # Change to the desired version
thorium-channel = "x64";            # Leave as "x64" for 64-bit Linux
```

You'll also need to update the SHA256 hash. You can get this by first changing the version, then attempting to build with an incorrect hash. Nix will show the correct hash in the error message.

### Customizing Flags

The browser wrapper applies some common flags by default, including Wayland support. You can customize this by editing the `postFixup` phase in the derivation:

```nix
postFixup = ''
  makeWrapper $out/opt/chromium.org/thorium/thorium-browser $out/bin/thorium-browser \
    --prefix LD_LIBRARY_PATH : ${pkgs.lib.makeLibraryPath buildInputs} \
    --prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.xdg-utils ]} \
    --add-flags "--your-custom-flags-here" \
    # ...existing flags...
'';
```

## Troubleshooting

### Missing Libraries

If you encounter library-related errors, you may need to add additional dependencies to the `buildInputs` list in `flake.nix`.

Common missing libraries and their packages:
- libva issues: Add `libva` and/or `intel-media-driver` (for Intel GPUs)
- Audio issues: Check `pulseaudio` and `alsa-lib` are included
- GPU acceleration: Ensure `mesa` and relevant GPU drivers are included

### Wayland Issues

If you're having problems with Wayland:

1. Ensure the `NIXOS_OZONE_WL` environment variable is set (the wrapper checks for this)
2. Try launching with explicit flags: `thorium-browser --ozone-platform=wayland`

## Building from Source

To build from the official Thorium source code instead of using the .deb package, a more complex derivation would be needed. This flake uses the official .deb release for simplicity and reliability.

## License

This flake is provided under the [MIT License](LICENSE).
Thorium Browser itself is licensed under the BSD 3-Clause license.
