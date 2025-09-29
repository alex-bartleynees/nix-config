{ lib, pkgs, myUsers, username, ... }: {
  programs.git = lib.mkMerge [
    {
      enable = true;
      extraConfig = {
        init.defaultBranch = "main";

        core = {
          editor = "nvim";
          whitespace = "fix,-indent-with-non-tab,trailing-space,cr-at-eol";
          pager = "delta";
        };

        diff = { tool = "vimdiff"; };

        difftool = { prompt = false; };

        pull = { rebase = true; };
      };
    }
    (lib.mkIf (myUsers.${username} ? git) {
      userName = myUsers.${username}.git.userName;
      userEmail = myUsers.${username}.git.userEmail;
    })
  ];

  home.packages = with pkgs; [ delta ];
}
