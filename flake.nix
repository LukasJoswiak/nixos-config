{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-secrets = {
      url = "github:LukasJoswiak/nix-secrets";
    };
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-homebrew = {
      url = "github:zhaofengli/nix-homebrew";
    };
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
  };

  outputs = inputs@{ self, nix-secrets, nix-darwin, nixpkgs, home-manager, nix-homebrew, homebrew-core, homebrew-cask }:
  let
    configuration = { pkgs, ... }: {
      # List packages installed in system profile. To search by name, run:
      # $ nix-env -qaP | grep wget
      environment.systemPackages = with pkgs; [ git-remote-gcrypt ];

      homebrew = {
        enable = true;

        brews = [];
        casks = [
          "1password"
          "keepingyouawake"
          "ghostty"
          "programmer-dvorak"
        ];

        # These app IDs are from using the mas CLI app
        # mas = mac app store
        # https://github.com/mas-cli/mas
        #
        # $ nix shell nixpkgs#mas
        # $ mas search <app name>
        masApps = {
          "1blocker" = 1365531024;
          "1password_for_safari" = 1569813296;
          "wireguard" = 1451685025;
        };
      };

      system = {
        primaryUser = "lukasjoswiak";
        keyboard = {
          enableKeyMapping = true;
          remapCapsLockToControl = true;
        };

        defaults = {
          dock = {
            autohide = true;
            orientation = "left";
            persistent-apps = [
              "/System/Applications/Calendar.app"
              "/Applications/Safari.app"
              "/System/Applications/Mail.app"
              "/System/Applications/Messages.app"
              "/Users/lukasjoswiak/Applications/Home Manager Apps/Alacritty.app"
              "/Applications/Ghostty.app"
            ];
            show-recents = false;
            # Hot corners
            wvous-tl-corner = 1;   # disabled
            wvous-bl-corner = 1;   # disabled
            wvous-tr-corner = 1;   # disabled
            wvous-br-corner = 13;  # lock screen
          };
          trackpad = {
            Clicking = true;
            TrackpadThreeFingerDrag = true;
            TrackpadThreeFingerHorizSwipeGesture = 0;
          };
          NSGlobalDomain = {
            KeyRepeat = 2;
            InitialKeyRepeat = 17;
            NSAutomaticCapitalizationEnabled = false;
            NSAutomaticDashSubstitutionEnabled = false;
            NSAutomaticPeriodSubstitutionEnabled = false;
            NSAutomaticQuoteSubstitutionEnabled = false;
            NSAutomaticSpellingCorrectionEnabled = false;
            ApplePressAndHoldEnabled = false;
            AppleICUForce24HourTime = true;
          };
        };
      };

      users.users.lukasjoswiak.home = "/Users/lukasjoswiak";

      # Let Determinate Nix handle Nix configuration
      nix.enable = false;

      # Necessary for using flakes on this system.
      nix.settings.experimental-features = "nix-command flakes";

      # Set Git commit hash for darwin-version.
      system.configurationRevision = self.rev or self.dirtyRev or null;

      # Used for backwards compatibility, please read the changelog before changing.
      # $ darwin-rebuild changelog
      system.stateVersion = 6;

      # The platform the configuration will be used on.
      nixpkgs.hostPlatform = "aarch64-darwin";

      security.pam.services.sudo_local.touchIdAuth = true;
    };
  in
  {
    # Build darwin flake using:
    # $ sudo darwin-rebuild switch --flake ~/.config/nix-darwin
    darwinConfigurations."mbp-5" = nix-darwin.lib.darwinSystem {
      modules = [
        configuration

        nix-secrets.darwinModules.secrets

        home-manager.darwinModules.home-manager ({ config, ... }: {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.lukasjoswiak = import ./home.nix;
          home-manager.extraSpecialArgs = {
            age = config.age;
            email = config.email;
            sshConfig = config.sshConfig;
          };
        })

        nix-homebrew.darwinModules.nix-homebrew {
          nix-homebrew = {
            enable = true;
            # enableRosetta = true;
            user = "lukasjoswiak";

            taps = {
              "homebrew/homebrew-core" = homebrew-core;
              "homebrew/homebrew-cask" = homebrew-cask;
            };
            mutableTaps = false;
          };
        }
      ];
    };
  };
}
