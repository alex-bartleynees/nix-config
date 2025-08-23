{ config, ... }:
let
  username = builtins.head
    (builtins.filter (user: config.users.users.${user}.isNormalUser)
      (builtins.attrNames config.users.users));
in {
  sops = {
    defaultSopsFile = ../../secrets/secrets.yaml;
    age.keyFile = "/home/${username}/.config/sops/age/keys.txt";
    secrets = {
      # User passwords
      "passwords/root".neededForUsers = true;
      "passwords/alexbn".neededForUsers = true;

      # Samba secrets
      "samba/password" = { };
      "samba/username" = { };
    };
  };
}
