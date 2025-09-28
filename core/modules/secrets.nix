{ users, lib, ... }:
let
  userPasswordSecrets = lib.listToAttrs (map (user: {
    name = "passwords/${user.username}";
    value = {
      neededForUsers = true;
      mode = "0400";
      owner = "root";
    };
  }) users);
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
