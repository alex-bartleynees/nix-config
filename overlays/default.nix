final: prev: {
  # nixos-unstable currently ships lttng-tools-2.14.1 alongside lttng-ust-2.14.0,
  # a desynced pair whose ABI headers don't match (channel.cpp references
  # `attr.u.s.type`, which lttng-ust 2.14.0 doesn't define). lttng-tools only
  # reaches our closure as libmsquic's optional tracing backend (used by
  # technitium-dns-server), and msquic's CMake gracefully disables tracing
  # when lttng-ust headers aren't present, so drop the dependency instead of
  # waiting for nixpkgs to fix the version pairing.
  libmsquic = prev.libmsquic.overrideAttrs (old: {
    buildInputs =
      builtins.filter (p: (p.pname or p.name or "") != "lttng-tools")
      old.buildInputs;
  });

  # nixpkgs removed libdisplay-info_0_2 (default is now 0.4.0, throw alias
  # left behind), but niri-flake hard-asserts version 0.2.0 to match niri's
  # vendored bindings, breaking eval on any host with desktop = "niri".
  # Upstream fix (sodiboo/niri-flake#1851, PR #1853) isn't merged yet and
  # our niri pin is already at branch tip, so bumping can't help. Resurrect
  # the old derivation via overrideAttrs -- 0.2.0 and 0.4.0 have identical
  # deps/patches, only src differs. Drop once #1853 lands and niri is bumped.
  libdisplay-info_0_2 = prev.libdisplay-info.overrideAttrs (old: {
    name = "libdisplay-info-0.2.0";
    version = "0.2.0";
    src = prev.fetchFromGitLab {
      domain = "gitlab.freedesktop.org";
      owner = "emersion";
      repo = "libdisplay-info";
      rev = "0.2.0";
      hash = "sha256-6xmWBrPHghjok43eIDGeshpUEQTuwWLXNHg7CnBUt3Q=";
    };
  });
}
