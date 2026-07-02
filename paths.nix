self: {
  modules        = "${self}/modules";
  profiles       = "${self}/profiles";
  homeProfiles   = "${self}/profiles/home-profiles";
  darwinProfiles = "${self}/profiles/darwin";
  desktops       = "${self}/desktops";
  themes         = "${self}/themes";
  hardware       = "${self}/hardware";
  diskConfigs    = "${self}/hardware/disk-config";
  users          = "${self}/users";
}
