{ pkgs, ... }:
{
  # Allow non-free (Unfree) packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
   environment.systemPackages = with pkgs; [
     nano # Why would I ever want vim to touch my system :)
     wget
     sbctl
     niv
   ];
}
