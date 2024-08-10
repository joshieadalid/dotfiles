{ config, pkgs, lib, ... }:

{
  # Imports
  imports = [
    ./hardware-configuration.nix
  ];

  # Bootloader
  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    kernelPackages = pkgs.linuxPackages_xanmod_latest;
    kernelParams = [ "psmouse.synaptics_intertouch=0" ];
    supportedFilesystems = [ "ntfs" ];
  };
  
  # Networking
  networking = {
    hostName = "latitude-joshieadalid";
    
    networkmanager = {
      enable = true;
      dns = "none";
    };
    
    nameservers = [ "127.0.0.1" "::1" ];
    firewall = {
      enable = true;
      allowedTCPPortRanges = [ { from = 27015; to = 27050; } ];
      allowedUDPPortRanges = [ { from = 27000; to = 27031; } ];
      allowedUDPPorts = [ 443 4380 27036 62056 62900 51820 ];
      allowedTCPPorts = [ 18232 ];
    };
    
    dhcpcd.extraConfig = "nohook resolv.conf";
    
    hosts = {
      "148.204.58.195" = [ "pc-058-195.escom.ipn.mx" ];
    };
  };
  networking.firewall.checkReversePath = false; 
  services.chrony.enable = true;
  programs.nm-applet.enable = true;

  # Timezone and Locale
  time.timeZone = "America/Mexico_City";
  i18n.defaultLocale = "es_MX.UTF-8";

  # X11 and Desktop Environment
  services.xserver.enable = true;
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;
  services.xserver.xkb.layout = "latam";
  services.xserver.xkb.variant = "";
  console.keyMap = "la-latin1";

  # Sound
  sound.enable = true;
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa = {
      enable = true;
      support32Bit = true;
    };
    
    pulse.enable = true;
  };

  # Printing
  services.printing.enable = true;
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  services.printing.drivers = [ pkgs.hplip ];
  
  users.users.joshieadalid = {
    isNormalUser = true;
    description = "Josué Adalid";
    extraGroups = [ "networkmanager" "wheel" "libvirtd" ];
    
    packages = with pkgs; [
      xarchiver
      google-chrome
      geoclue2
    ];
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # System Packages
  environment.systemPackages = with pkgs; [
    wineWowPackages.stable
    winetricks
    lm_sensors
    python3
    hplip
    nmap
    gparted
    htop
    tree
    udp2raw
    dnsmasq
  ];

  # DNSCrypt Proxy
  services.dnscrypt-proxy2 = {
    enable = true;
    settings = {
      ipv6_servers = true;
      require_dnssec = true;
      sources.public-resolvers = {
       urls = [
          "https://raw.githubusercontent.com/DNSCrypt/dnscrypt-resolvers/master/v3/public-resolvers.md"
          "https://download.dnscrypt.info/resolvers-list/v3/public-resolvers.md"
        ];
        cache_file = "/var/lib/dnscrypt-proxy2/public-resolvers.md";
        minisign_key = "RWQf6LRCGA9i53mlYecO4IzT51TGPpvWucNSCh1CBM0QTaLn73Y7GFO3";
      };
       server_names = ["cloudflare" "google"]; # Uncomment to use specific servers
    };
  };
  
  systemd.services.dnscrypt-proxy2.serviceConfig = {
    StateDirectory = "dnscrypt-proxy";
  };

  services.mysql = {
    enable = true;
    package = pkgs.mariadb;
  };

  # Nix Configuration
  nix.optimise.automatic = true;
  nix.settings.auto-optimise-store = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Virtualization
  virtualisation.libvirtd.enable = true;
  programs.virt-manager.enable = true;
  virtualisation.docker.rootless = {
    enable = true;
    setSocketVariable = true;
  };

  # Power Management
  powerManagement.cpuFreqGovernor = "powersave";
  services.thermald.enable = true;
  services.auto-cpufreq.enable = true;

  # Steam
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
  };

  # Geolocation
  location.provider = "geoclue2";

  # Redshift
  services.redshift = {
    enable = true;
    brightness = {
      day = "1";
      night = "1";
    };
    temperature = {
      day = 5500;
      night = 3700;
    };
  };

  # OpenGL
  hardware.opengl.enable = true;
 

  # Enable WireGuard
  networking.wireguard.interfaces = {
    # "wg0" is the network interface name. You can name the interface arbitrarily.
    wg0 = {
      # Determines the IP address and subnet of the client's end of the tunnel interface.
      ips = [ "10.100.0.2/24" ];
      # listenPort = 51820; # to match firewall allowedUDPPorts (without this wg uses random port numbers)

      # Path to the private key file.
      #
      # Note: The private key can also be included inline via the privateKey option,
      # but this makes the private key world-readable; thus, using privateKeyFile is
      # recommended.
      privateKeyFile = "/home/joshieadalid/wireguard-keys/private";

      peers = [
        # For a client configuration, one peer entry for the server will suffice.

        {
          # Public key of the server (not a file path).
          publicKey = "mVvMsJRvfRiZstBqWqduneEYYu02FxXGZXlu6QPI2XI=";

          # Forward all the traffic via VPN.
          allowedIPs = [ "0.0.0.0/0" ];
          # Or forward only particular subnets
          #allowedIPs = [ "10.100.0.1" "91.108.12.0/22" ];

          # Set this to the server IP and port.
          endpoint = "148.204.58.178:443"; # ToDo: route to endpoint not automatically configured https://wiki.archlinux.org/index.php/WireGuard#Loop_routing https://discourse.nixos.org/t/solved-minimal-firewall-setup-for-wireguard-client/7577

          # Send keepalives every 25 seconds. Important to keep NAT tables alive.
          persistentKeepalive = 25;
        }
      ];
    };
  };

  # System State Version
  system.stateVersion = "23.11"; 
}
