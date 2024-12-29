{ config, pkgs, ... }: {
  security.pam.services.gdm.enableGnomeKeyring = true;
  security.pam.services.swaylock = { text = "auth include login"; };
  security.pam.services.login.enableGnomeKeyring = true;
  security.pam.services.greetd.enableGnomeKeyring = true;
}
