{ pkgs ? import <nixpkgs> {}, ceremony-rsvp-password ? "secret" }:

let lua-resty-package = { name, version, github-owner, sha256 }:
      let pkg-name = name; in
       pkgs.luajitPackages.buildLuaPackage rec {
         _name  = "lua-resty-${pkg-name}";
         inherit version;
         name = "${_name}-${version}";
         src = pkgs.fetchFromGitHub {
           owner = github-owner;
           repo = _name;
           rev = version;
           inherit sha256;
         };

         dontBuild = true;
         installPhase = ''
          mkdir -p $out/lib
          cp -a lib/resty $out/lib/
         '';
       };

   lua-resty-packages = map lua-resty-package [
     {
       name  = "cookie";
       version = "v0.1.0";
       github-owner = "cloudflare";
       sha256 = "03ch2gwsvvwhz3hs0m2fvrhc5899irlmakdafxvamchb8wngxkpf";
     }
     {
       name = "mail";
       version = "74abf68f763b8eb67dd521b7dd894427684a942f";
       github-owner = "GUI";
       sha256 = "078km18fldsmlw6bamw39fyscdp34afwg6yaa55p9mrp6nj2ikga";
     }
     {
       name = "random";
       version = "17b604f7f7dd217557ca548fc1a9a0d373386480";
       github-owner = "bungle";
       sha256 = "095g88ka06q33lbypsavb0kmqv31yxidwl6w4qy6ram50w50zph7";
     }
     {
       name = "string";
       version = "a55eb9e3e0f08e1797cd5b31ccea9d9b05e5890b";
       github-owner = "openresty";
       sha256 = "1yl6s6hv3f9rwgvb8kk8pzwnvjqzl51gvi8z28qqxkhif24hykgz";
     }
     {
       name  = "template";
       version = "v1.9";
       github-owner = "bungle";
       sha256 = "0ga1kcpn34w0cxd35spa5cdkr4jsvqs6f4sdjcis19vczdasx16s";
     }
   ];
   lua-resty-path = pkgs.lib.concatMapStringsSep ";" (p : "${p}/lib/?.lua") lua-resty-packages;

   alt-getopt = pkgs.luajitPackages.buildLuaPackage rec {
     name = "alt-getopt-${version}";
     version = "0.8.0";
     src = pkgs.fetchFromGitHub {
       owner = "cheusov";
       repo = "lua-alt-getopt";
       rev = version;
       sha256 = "1kq7r5668045diavsqd1j6i9hxdpsk99w8q4zr8cby9y3ws4q6rv";
     };

     dontBuild = true;

     installPhase = ''
       mkdir -p $out/lib/alt_getopt
       cp alt_getopt.lua $out/lib/alt_getopt
     '';

     meta = {
       description = "A language that compiles to Lua";
       homepage = "http://moonscript.org";
       license = pkgs.stdenv.lib.licenses.mit;
     };
   };

  moonscript = pkgs.luaPackages.buildLuaPackage rec {
     name = "moonscript-${version}";
     version = "v0.5.0";
     src = pkgs.fetchFromGitHub {
       owner = "leafo";
       repo = "moonscript";
       rev = version;
       sha256 = "0bx6xici852ji5a1zjsrmvr90ynrfykkhwgc5sdj5gvvnhz5k4fd";
     };

     buildInputs = [ pkgs.makeWrapper ];
     propagatedBuildInputs = with pkgs.luaPackages; [ alt-getopt luafilesystem lpeg ];

     buildPhase = with pkgs.luaPackages; ''
       sed '/^LUA_C?PATH_MAKE = /d' -i Makefile
       export LUA_PATH='${alt-getopt}/lib/?/?.lua;./?.lua;./?/init.lua'
       export LUA_CPATH='${luafilesystem}/lib/lua/5.2/?.so;${lpeg}/lib/lua/5.2/?.so'
       make compile LUA=${lua}/bin/lua LUAROCKS=${luarocks}/bin/luarocks LUA_PATH_MAKE="$LUA_PATH" LUA_CPATH_MAKE="$LUA_CPATH"
     '';

     installPhase = with pkgs.luaPackages; ''
       mkdir -p $out/bin
       mkdir -p $out/lib
       cp -a moonscript $out/lib/
       cp bin/moon bin/moonc $out/bin/
       wrapProgram $out/bin/moonc \
        --set LUA_PATH "$out/lib/?.lua;${alt-getopt}/lib/?/?.lua;./?.lua;./?/init.lua" \
        --set LUA_CPATH "${luafilesystem}/lib/lua/5.2/?.so;${lpeg}/lib/lua/5.2/?.so"
       wrapProgram $out/bin/moon \
        --set LUA_PATH "$out/lib/?.lua;$out/lib/?.lua;${alt-getopt}/lib/?/?.lua;./?.lua;./?/init.lua" \
        --set LUA_CPATH "${luafilesystem}/lib/lua/5.2/?.so;${lpeg}/lib/lua/5.2/?.so"
     '';

     meta = {
       description = "A language that compiles to Lua";
       homepage = "http://moonscript.org";
       license = pkgs.stdenv.lib.licenses.mit;
     };
   };


   pgmoon = pkgs.luajitPackages.buildLuaPackage rec {
     _name  = "pgmoon";
     version = "1.8.0";
     name = "${_name}-${version}";
     src = pkgs.fetchFromGitHub {
       owner = "leafo";
       repo = _name;
       rev = "v${version}";
       sha256 = "1ghhqdgm6i5vnr2bw18a19i77j9xbwbb6wn0k81ffpdqrhm0xish";
     };

     buildInputs = [ moonscript pkgs.luajit];
     installPhase = ''
      mkdir -p $out/lib
      cp -a pgmoon $out/lib/
     '';
   };
in rec {
  site = pkgs.stdenv.mkDerivation {
    name = "ceremony-rsvp";

    src = ./.;

    #propagatedBuildInputs = with pkgs.python3Packages; [ docopt psycopg2 ];

    buildPhase = "";

    installPhase = ''
      mkdir -p $out
      cp -ax templates $out/

      mkdir -p $out/bin
      cp setup.sh $out/bin
      substitute setup.sh $out/bin/setup.sh --replace @SUDO ${pkgs.sudo} --replace @POSTGRESQL ${pkgs.postgresql} --replace @OUT $out --replace @PASSWORD ${ceremony-rsvp-password}
      chmod +x $out/bin/setup.sh

      mkdir -p $out/db
      cp db/*.sql $out/db/
      substitute db/run.sh $out/db/run.sh --replace @POSTGRESQL ${pkgs.postgresql} --replace @OUT $out --replace @PASSWORD ${ceremony-rsvp-password}
      chmod +x $out/db/run.sh

      mkdir -p $out/lib
      cp lib/handler.lua $out/lib/
    '';

    doCheck = false;

    meta = {
      homepage = http://github.com/edanaher/ceremony-rsvp;
      description = "RSVP site for the ceremony";
      license = pkgs.stdenv.lib.licenses.bsd3;
    };
  };


  service = {
    description = "Set up the rsvp website database";
    after = [ "network.target" "postgresql.service" ];
    wantedBy = [ "multi-user.target" ];
    environment = { TZ = "America/Los_Angeles"; };
    serviceConfig =  {
      Type = "oneshot";
      ExecStart = "${site}/bin/setup.sh";
      Restart = "no";
      RestartSec = "4h";
      StartLimitInterval = "1min";
      PermissionsStartOnly = "true"; # Run postgres setup as root
      User = "root";
    };

    preStart = ''
      
    '';
  };

  lua-path = "${pgmoon}/lib/?.lua;${pgmoon}/lib/?/init.lua;${lua-resty-path}";
  nginx-locations = {
    #locations."/_static".alias = "${site}/static";
    locations."/" = {
      extraConfig = ''
        default_type text/html;
        content_by_lua_file ${site}/lib/handler.lua;
        set $template_root ${site}/templates;
        set $ceremony-rsvp-password ${ceremony-rsvp-password};
      '';
    };
  };

}
