{ config, lib, pkgs, age, sshConfig, email, ... }:

{
  home.stateVersion = "25.11";

  home.packages = with pkgs; [
    ansible
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
    matchBlocks = {} // sshConfig.matchBlocks;
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

  programs.alacritty = {
    enable = true;
  };

  programs.ghostty = {
    enable = true;
    package = if pkgs.stdenv.isDarwin then null else pkgs.ghostty;
    settings = {
      font-feature = "-calt";
      cursor-style-blink = false;
      theme = "Argonaut";
    };
  };

  targets.darwin.defaults = {
    "com.apple.Safari" = {
      AutoFillPasswords = false;
      AutoFillCreditCardData = false;
      AutoOpenSafeDownloads = false;
      IncludeDevelopMenu = true;
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
}
