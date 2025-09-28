{ users, lib, config, ... }:
let
  usersWithSecrets = lib.filter
    (user: config.myUsers.${user.username}.needsPasswordSecret or false) users;

  userPasswordSecrets = lib.listToAttrs (map (user: {
    name = "passwords/${user.username}";
    value = {
      neededForUsers = true;
      mode = "0400";
      owner = "root";
    };
  }) usersWithSecrets);
in {
  sops = {
    defaultSopsFile = ../../secrets/secrets.yaml;
    age.keyFile = "/etc/sops/age/keys.txt";
    secrets = {
      # User passwords
      "passwords/root" = {
        neededForUsers = true;
        mode = "0400";
        owner = "root";
      };

      # Samba secrets
      "samba/password" = { };
      "samba/username" = { };
    } // userPasswordSecrets;
  };
}
