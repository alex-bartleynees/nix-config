final: prev: {
  # nixos-unstable currently ships lttng-tools-2.14.1 alongside lttng-ust-2.14.0,
  # a desynced pair whose ABI headers don't match (channel.cpp references
  # `attr.u.s.type`, which lttng-ust 2.14.0 doesn't define). lttng-tools only
  # reaches our closure as libmsquic's optional tracing backend (used by
  # technitium-dns-server), and msquic's CMake gracefully disables tracing
  # when lttng-ust headers aren't present, so drop the dependency instead of
  # waiting for nixpkgs to fix the version pairing.
  libmsquic = prev.libmsquic.overrideAttrs (old: {
    buildInputs = builtins.filter
      (p: (p.pname or p.name or "") != "lttng-tools") old.buildInputs;
  });
}
