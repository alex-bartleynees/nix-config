{ username, ... }: {
  workPersistPaths = [
    "/home/${username}/.config/teams-for-linux"
    "/home/${username}/.local-certs"
    "/home/${username}/.local/share/mkcert"
  ];
}
