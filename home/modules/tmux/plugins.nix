{ pkgs }: {
  tokyo-night = pkgs.tmuxPlugins.mkTmuxPlugin {
    pluginName = "tmux-tokyo-night";
    version = "1.10.0";
    rtpFilePath = "tmux-tokyo-night.tmux";
    src = pkgs.fetchFromGitHub {
      owner = "fabioluciano";
      repo = "tmux-tokyo-night";
      rev = "5ce373040f893c3a0d1cb93dc1e8b2a25c94d3da";
      sha256 = "sha256-9nDgiJptXIP+Hn9UY+QFMgoghw4HfTJ5TZq0f9KVOFg=";
    };
  };
}
