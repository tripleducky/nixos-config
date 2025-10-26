# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "America/Costa_Rica";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "es_CR.UTF-8";
    LC_IDENTIFICATION = "es_CR.UTF-8";
    LC_MEASUREMENT = "es_CR.UTF-8";
    LC_MONETARY = "es_CR.UTF-8";
    LC_NAME = "es_CR.UTF-8";
    LC_NUMERIC = "es_CR.UTF-8";
    LC_PAPER = "es_CR.UTF-8";
    LC_TELEPHONE = "es_CR.UTF-8";
    LC_TIME = "es_CR.UTF-8";
  };

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.andre = {
    isNormalUser = true;
    description = "andre";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [];
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
  programs.niri.enable = true;
  services.displayManager.ly.enable = true;
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
  };
  fonts.packages = with pkgs; [ nerd-fonts.symbols-only ];
  
  xdg.portal = {
    enable = true;
    # Prefer wlroots + GTK backends with niri; keep GNOME portal available
    # but do not prefer it, since it requires gnome-shell.
    extraPortals = with pkgs; [
      xdg-desktop-portal-wlr
      xdg-desktop-portal-gtk
      xdg-desktop-portal-gnome
    ];
    # Explicitly set priorities so screencast/screenshot use wlr.
    config = {
      common = {
        default = [ "wlr" "gtk" "gnome" ];
        "org.freedesktop.impl.portal.Screencast" = [ "wlr" ];
        "org.freedesktop.impl.portal.Screenshot" = [ "wlr" ];
      };
    };
  };
  
  services.pipewire.enable = true;
  services.pipewire.alsa.enable = true;
  services.pipewire.pulse.enable = true;
  
  services.upower.enable = true;

  # RealtimeKit for PipeWire/portals (was previously missing under services.*)
  security.rtkit.enable = true;

  # Enable Flatpak support (system-wide) so you can install apps from Flathub
  services.flatpak.enable = true;

  # Ensure session DBus and keyring are running so Electron apps (e.g., GitHub Desktop)
  # can complete OAuth flows and store credentials via libsecret.
  services.dbus.enable = true;
  services.gnome.gnome-keyring.enable = true;
  # PolicyKit (polkit) and a desktop auth agent so GUI apps (like VS Code) can
  # elevate privileges when saving system files via a prompt.
  security.polkit.enable = true;
  programs.dconf.enable = true;
  systemd.user.services.polkit-gnome-authentication-agent-1 = {
    description = "polkit-gnome authentication agent";
    after = [ "graphical-session.target" ];
    wants = [ "graphical-session.target" ];
    wantedBy = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
      Restart = "on-failure";
    };
  };
  security.pam.services = {
    # Enable keyring unlock for TTY/login and ly display manager sessions.
    login.enableGnomeKeyring = true;
    ly.enableGnomeKeyring = true;
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  
  nixpkgs.overlays = [
    (import ./overlays.nix)
  ];
  
  environment.systemPackages = with pkgs; [
      msedit
      quickshell
      firefox
      rofi
      git
      alacritty
      fastfetch
      swww
      just
      cmake
      gnumake
      gcc
      qt6.qtbase
      qt6.wrapQtAppsHook
      gdb
      makeWrapper
      qml-niri
      kanshi
      xwayland-satellite
      vscode
      fuzzel
      # Theming packages to match previous Home Manager config
      pop-gtk-theme
      papirus-icon-theme
      gnome-keyring
      nautilus
      lxappearance
      github-desktop
      polkit_gnome # polkit authentication agent binary
    ];
  
  # Revert to non-flakes workflow; keep nix-command for nicer UX
  nix.settings.experimental-features = [ "nix-command" ];

  # Session environment (system-wide) replacing Home Manager sessionVariables
  environment.sessionVariables = {
    # Prefer Wayland for compatible apps; Electron/Chromium & Firefox
    NIXOS_OZONE_WL = "1";
    MOZ_ENABLE_WAYLAND = "1";
    GTK_THEME = "Pop-dark"; # enforce GTK theme if per-user settings are absent/overriding
    # QML import path for qml-niri module
    QML2_IMPORT_PATH = "${pkgs.qml-niri}/lib/qt-6/qml";
    QML_IMPORT_PATH = "${pkgs.qml-niri}/lib/qt-6/qml";
  };

  # System-wide defaults replacing Home Manager xdg.mimeApps
  environment.etc."xdg/mimeapps.list".text = ''
    [Default Applications]
    x-scheme-handler/x-github-client=github-desktop.desktop
    x-scheme-handler/x-github-desktop-auth=github-desktop.desktop
  '';

  # System-wide GTK theme defaults replacing Home Manager gtk.*
  # Write to both traditional /etc/gtk-*/ and XDG /etc/xdg/gtk-*/ locations
  environment.etc."gtk-3.0/settings.ini".text = ''
    [Settings]
    gtk-theme-name=Pop-dark
    gtk-icon-theme-name=Papirus-Dark
  '';
  environment.etc."gtk-4.0/settings.ini".text = ''
    [Settings]
    gtk-theme-name=Pop-dark
    gtk-icon-theme-name=Papirus-Dark
  '';
  environment.etc."xdg/gtk-3.0/settings.ini".text = ''
    [Settings]
    gtk-theme-name=Pop-dark
    gtk-icon-theme-name=Papirus-Dark
  '';
  environment.etc."xdg/gtk-4.0/settings.ini".text = ''
    [Settings]
    gtk-theme-name=Pop-dark
    gtk-icon-theme-name=Papirus-Dark
  '';
  
  

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?

}
