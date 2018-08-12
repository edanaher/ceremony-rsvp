{ pkgs ? import <nixpkgs> {}, config, options, lib, modulesPath }:

let rsvp = import ./default.nix { inherit pkgs ceremony-rsvp-password; };
    ceremony-rsvp-password = "secret";
    site = rsvp.site;
in
{
  environment.systemPackages = [ site pkgs.postgresql ];

  systemd.services.init-rsvp-ceremony = rsvp.service;

  services.postgresql.enable = true;
  services.postgresql.authentication = ''
    local rsvpsite rsvpsite md5
    local all all peer
  '';

  users.users.rsvpsite = {
    description = "User to run the rsvp ceremony site";
  };

  networking.firewall.enable = false;
  services.nginx.enable = true;
  services.nginx.package = (pkgs.nginx.overrideAttrs (oldAttrs: { configureFlags = oldAttrs.configureFlags ++ [/*"--with-ld-opt=${pgmoon}/doesnotexit"*/]; } )).override { modules = with pkgs.nginxModules; [ lua ]; };
  services.nginx.appendHttpConfig = ''
    lua_package_path ";;${rsvp.lua-path}";
  '';
  services.nginx.virtualHosts = {
    "localhost" = rsvp.nginx-locations;
  };

  system.nixos.stateVersion = "18.09";
}
