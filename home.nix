{ config, lib, pkgs, age, sshConfig, email, resticRepositoryFile, resticPasswordCommand, ... }:
let
  resticBackupScript = pkgs.writeShellScript "restic-backup" ''
    export RESTIC_REPOSITORY_FILE="${resticRepositoryFile}"
    export RESTIC_PASSWORD_COMMAND="${resticPasswordCommand}"

    if ! ping -c1 -W2 192.168.1.20 >/dev/null 2>&1; then
      echo "NAS unreachable, skipping backup"
      exit 0
    fi

    # Initialize the repo if it doesn't exist
    if ! ${pkgs.restic}/bin/restic snapshots >/dev/null 2>&1; then
      echo "Repository not initialized, running restic init..."
      ${pkgs.restic}/bin/restic init
    fi

    ${pkgs.restic}/bin/restic backup \
      "/Users/lukasjoswiak/Documents" \
      "/Users/lukasjoswiak/dev" \
      "/Users/lukasjoswiak/Mail" \
      --tag daily

    ${pkgs.restic}/bin/restic forget \
      --keep-daily 7 --keep-weekly 5 --keep-monthly 12 --keep-yearly 75 \
      --prune
  '';
in
{
  home.stateVersion = "25.11";

  home.packages = with pkgs; [
    ansible
    jujutsu
    llama-cpp
    restic
    tree
    pulseview
  ];

  programs.zsh = {
    enable = true;
    history.save = 10000;
    initContent = ''
      PROMPT="%~ %# "
    '';
  };

  programs.git = {
    enable = true;
    settings = {
      user.name = "Lukas Joswiak";
      user.email = "lukas@lukasjoswiak.com";
      init.defaultBranch = "main";
    };
  };

  programs.ripgrep.enable = true;
  programs.fzf.enable = true;

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings = {
      "*" = {
        SetEnv = {
          TERM = "xterm-256color";
        };
      };
    } // sshConfig.matchBlocks;
  };

  programs.password-store.enable = true;
  programs.gpg.enable = true;
  services.gpg-agent = {
    enable = true;
    pinentry.package = pkgs.pinentry_mac;
  };

  programs.vim = {
    enable = true;
    defaultEditor = true;
    settings = {
      number = true;
      relativenumber = true;
    };
    plugins = [ pkgs.vimPlugins.fzf-vim ];
    extraConfig = ''
      let mapleader = ","

      " fzf remaps
      nmap ; :Buffers<CR>
      nmap <Leader>t :Files<CR>
      nmap <Leader>r :Rg<CR>
      nmap <Leader>m :Marks<CR>

      " Move between Vim panes
      nmap <Leader>h <C-W>h
      nmap <Leader>j <C-W>j
      nmap <Leader>k <C-W>k
      nmap <Leader>l <C-W>l

      " Save file with cs
      nmap cs :w<CR>
      " Remap escape to jj
      imap jj <Esc>

      set noswapfile     " Disable swap files
      syntax on          " Turn on syntax highlighting
      " set number         " Enable line numbers
      " set relativenumber " Current line shows absolute line number
      set ruler          " Show row and column information
      set hlsearch       " Enable highlight on search
      set hidden         " Hide buffers instead of abandoning them

      set autoindent
      set expandtab      " Expand tabs to spaces
      set tabstop=4
      set shiftwidth=4
      set softtabstop=4

      set mouse=         " Disable mouse

      " Indent with 2 spaces in cpp files
      au FileType cpp setlocal shiftwidth=2 softtabstop=2 expandtab

      " Indent with 2 spaces in C files
      au FileType c setlocal shiftwidth=2 softtabstop=2 expandtab
    '';
  };

  programs.emacs = {
    enable = true;
    package = pkgs.emacs-nox;
  };

  programs.alacritty = {
    enable = true;
  };

  programs.ghostty = {
    enable = true;
    package = if pkgs.stdenv.hostPlatform.isDarwin then null else pkgs.ghostty;
    settings = {
      font-feature = "-calt";
      cursor-style-blink = false;
      theme = "Argonaut";
      font-family = "CommitMono";
    };
  };

  targets.darwin.defaults = {
    NSGlobalDomain = {
      "com.apple.mouse.scaling" = 1.6;
    };
    "com.apple.Safari" = {
      AutoFillPasswords = false;
      AutoFillCreditCardData = false;
      AutoOpenSafeDownloads = false;
      IncludeDevelopMenu = true;
      PrivateBrowsingRequiresAuthentication = false;
      ShowFullURLInSmartSearchField = true;
      ShowOverlayStatusBar = true;
      WebAutomaticSpellingCorrectionEnabled = false;
      kTCCServiceLocation = "deny";
    };
    "com.apple.Siri" = {
      StatusMenuVisible = false;
      VoiceTriggerUserEnabled = false;
      AssistantEnabled = false;
    };
  };

  programs.aerc = {
    enable = true;
    extraConfig = {
      general.unsafe-accounts-conf = true;
      archive.default = "Archive";
      ui = {
        threading-enabled = true;
        sort = "-r date";
      };
      filters = {
        "text/plain" = "colorize";
      };
    };
  };

  programs.mbsync = {
    enable = true;
    extraConfig = ''
      CopyArrivalDate yes
    '';
  };

  programs.msmtp = {
    enable = true;
  };

  accounts.email = {
    maildirBasePath = "/Users/lukasjoswiak/Mail";
    accounts.lukas = email.accounts.lukas;
  };

  programs.firefox = {
    enable = true;
    package = null;
    policies = {
      DisableTelemetry = true;
      DontCheckDefaultBrowser = true;

      ExtensionSettings = {
        "uBlock0@raymondhill.net" = {
          default_area = "navbar";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
          installation_mode = "force_installed";
          private_browsing = "true";
        };
        "{d634138d-c276-4fc8-924b-40a0ea21d284}" = {
          default_area = "navbar";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/1password-x-password-manager/latest.xpi";
          installation_mode = "force_installed";
        };
        "ipvfoo@pmarks.net" = {
          default_area = "menupanel";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/ipvfoo/latest.xpi";
          installation_mode = "force_installed";
          private_browsing = "false";
        };
      };
    };
  };

  launchd.agents.restic-backup = {
    enable = true;
    config = {
      ProgramArguments = [ "${resticBackupScript}" ];
      # TODO: Run even if computer isn't awake at the scheduled time
      StartCalendarInterval = [ { Hour = 21; Minute = 0; } ];
      StandardOutPath = "${config.home.homeDirectory}/Library/Logs/restic-backup.log";
      StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/restic-backup-error.log";

    };
  };
}
