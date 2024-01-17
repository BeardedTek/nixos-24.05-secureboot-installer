{ pkgs, ... }:
{
  users = {
    mutableUsers = false;
    users = {
      nixos = {
        isNormalUser = true;
        description = "The Bearded Tek";
        createHome = true;
        home = "/home/nixos";
        group = "nixos";
        extraGroups = [ 
          "wheel"           # Enable sudo
          "systemd-journal"
        ];
        hashedPassword = "$6$oSqbHyYa7jFR7cpJ$MLhoJTuI5wGOP.7otQibyHUYiI2GbsF4UlZBiJ/Z7oeQFlpd9wqsiDh7RzDCAM5ySu2sgZYnvcGdnDvwH8Gh30";
        packages = with pkgs; [ ];
        uid = 1000;
      };
      root = {
        hashedPassword = "$6$oSqbHyYa7jFR7cpJ$MLhoJTuI5wGOP.7otQibyHUYiI2GbsF4UlZBiJ/Z7oeQFlpd9wqsiDh7RzDCAM5ySu2sgZYnvcGdnDvwH8Gh30";
      };
    };
    groups = {
      # Setup custom groups
      nixos = {
        name = "nixos";
        members = [ "nixos" ];
        gid = 1000;
      };
    };
  };
}
