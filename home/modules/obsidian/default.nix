{ pkgs, inputs, theme, ... }: {
  home.packages = with pkgs; [  (symlinkJoin {
      name = "obsidian";
      paths = [ obsidian ];
      buildInputs = [ makeWrapper ];
      postBuild = ''
        wrapProgram $out/bin/obsidian \
          --add-flags "--disable-gpu"
      '';
    })
 ];
}
