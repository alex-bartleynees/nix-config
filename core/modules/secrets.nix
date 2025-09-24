{ username, ... }: {
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
      "passwords/${username}" = {
        neededForUsers = true;
        mode = "0400";
        owner = "root";
      };

      # Samba secrets
      "samba/password" = { };
      "samba/username" = { };
    };
  };
}
