

# Configuración de Nix

Una configuración completa de Nix flake para gestionar configuraciones de sistema en múltiples hosts y plataformas (NixOS, macOS, WSL).
Soporte altamente flexible para múltiples hosts y usuarios.

## 🏗️ Estructura del Proyecto

```
├── flake.nix             # Configuración principal de Nix flake
├── hosts.nix             # Definiciones de hosts (monitores, perfiles, especializaciones)
├── desktops/             # Configuraciones de entorno de escritorio (módulos combinados de NixOS + Home Manager)
│   └── common/           # Módulos de escritorio compartidos (wayland, wlroots, linux-desktop)
├── hardware/             # Configuraciones de discos y perfiles de hardware
├── modules/              # Módulos del sistema central y módulos de aplicaciones de Home Manager
├── profiles/             # Perfiles de sistema y Home Manager con combinaciones comunes de módulos
├── secrets/              # Secretos cifrados con SOPS
├── lib/                  # Herramientas de configuración compartidas (mk-system, system-base, home-manager, module-utils, etc.)
├── themes/               # Temas del sistema (catppuccin, tokyo-night, gruvbox, nord, everforest)
└── users/                # Configuraciones específicas de usuario
```

### Arquitectura de Módulos

Cada archivo en `modules/` y `desktops/` utiliza una de tres estructuras, que `lib/module-utils.nix` enruta automáticamente:

**Solo NixOS** (función de módulo simple — sin envoltura):

```nix
{ config, lib, pkgs, ... }: {
  # Solo configuración del sistema NixOS
}
```

**Solo Home Manager** (envoltura `homeConfig`):

```nix
{
  homeConfig = { config, lib, pkgs, ... }: {
    # Solo configuración de Home Manager
  };
}
```

**Combinado** (ambas claves en un solo archivo):

```nix
{
  nixosConfig = { config, lib, pkgs, ... }: {
    # Configuración del sistema NixOS (servicios, PAM, etc.)
  };

  homeConfig = { config, lib, pkgs, ... }: {
    # Configuración de Home Manager (aplicaciones de usuario, archivos de configuración, etc.)
  };
}
```

`lib/module-utils.nix` exporta cuatro funciones utilizadas en todo el proyecto:

- `importAllNixFiles dir` — escanea un directorio y devuelve todos los módulos de NixOS (extrae `nixosConfig` de las envolturas; omite archivos solo `homeConfig`)
- `importHomeFiles dir` — escanea un directorio y devuelve todos los módulos de Home Manager (extrae `homeConfig`; omite todo lo demás)
- `extractSystemConfig desktop` — extrae `nixosConfig` de un archivo de escritorio con nombre
- `extractHomeConfig desktop` — extrae `homeConfig` de un archivo de escritorio con nombre (devuelve un módulo vacío si no existe)

### Activación Automática basada en Perfiles

Los módulos de Home Manager reciben un argumento especial `userProfiles` que contiene los perfiles del usuario activo. Los módulos utilizan esto para activarse automáticamente mediante `lib.mkDefault`:

```nix
homeConfig = { config, lib, pkgs, userProfiles ? [], ... }:
  let cfg = config.vscode; in {
    options.vscode.enable = lib.mkEnableOption "VS Code";

    config = lib.mkMerge [
      (lib.mkIf (builtins.elem "vscode" userProfiles) {
        vscode.enable = lib.mkDefault true;
      })
      (lib.mkIf cfg.enable { ... })
    ];
  };
```

Los perfiles de usuario se configuran en dos lugares:

```nix
# users/alexbn.nix — perfiles base siempre activos
myUsers.alexbn.profiles = [ "developer" ];

# hosts.nix — perfiles adicionales por host
additionalUserProfiles = {
  alexbn = [ "vscode" "rider" "reader" ];
};
```

## 🖥️ Configuración de Hosts

### hosts.nix

`hosts.nix` centraliza todas las definiciones de hosts. Cada host se define de forma declarativa con:

- **desktop**: Entorno de escritorio predeterminado
- **monitors**: Especificaciones de hardware por monitor (ver abajo)
- **enableThemeSpecialisations**: Activar cambio de tema en tiempo de ejecución
- **enableDesktopSpecialisations**: Activar cambio de entorno de escritorio
- **desktopSpecialisations**: Entornos de escritorio adicionales a compilar
- **systemProfiles**: Perfiles de sistema a activar
- **users**: Configuraciones de usuario
- **additionalModules**: Módulos específicos del host (hardware, WSL, etc.)

### Esquema de Monitores

La configuración del monitor se declara una vez por host en `hosts.nix` y se propaga automáticamente a cada compositor (Hyprland, Sway, Niri, River, Mango, GNOME):

```nix
monitors = [
  {
    name        = "DP-2";                      # nombre del conector
    description = "AOC U27G4 10GR2HA001383";  # usado por Hyprland para coincidir con desc:
    vendor      = "AOC";                       # usado por monitors.xml de GNOME
    product     = "U27G4";
    serial      = "10GR2HA001383";
    width       = 3840;
    height      = 2160;
    refresh     = 160.0;
    x           = 0;                           # posición lógica
    y           = 0;
    scale       = 1.5;
    vrr         = true;
    transform   = 0;                           # grados en sentido antihorario (convención Wayland): 0, 90, 180, 270
    hdr         = false;
    sdrBrightness = 1.0;                       # multiplicador de brillo SDR para HDR
    sdrSaturation = 1.0;                       # multiplicador de saturación SDR para HDR
    primary     = true;
  }
];
```

Agregar o renombrar un monitor solo requiere editar `hosts.nix`: todas las configuraciones del compositor, asignaciones de espacios de trabajo, comandos de inactividad/dpms y el XML de monitores de GNOME se derivan de esta única fuente.

### Hosts Disponibles

| Host       | Plataforma  | Escritorio  | Descripción                                                                  |
| ---------- | --------- | -------- | ---------------------------------------------------------------------------- |
| `desktop`  | NixOS     | Hyprland | Escritorio principal con especializaciones de tema y entorno (Sway, Niri, River, y más) |
| `macbook`  | macOS     | -        | Configuración de MacBook con nix-darwin                                      |
| `media`    | NixOS     | Hyprland | Servidor multimedia con Samba, servicios de copia de seguridad y pantalla HDR |
| `thinkpad` | NixOS     | Niri     | Portátil ThinkPad con gestión de energía TLP y especializaciones de tema      |
| `wsl`      | NixOS-WSL | None     | Configuración de Windows Subsystem for Linux                                 |

## 🚀 Inicio Rápido

### Sistemas NixOS

```bash
# Compilar y cambiar a la configuración del escritorio
sudo nixos-rebuild switch --flake .#desktop

# Compilar y cambiar a otros hosts
sudo nixos-rebuild switch --flake .#media
sudo nixos-rebuild switch --flake .#thinkpad
sudo nixos-rebuild switch --flake .#wsl
```

### Sistemas macOS

```bash
darwin-rebuild switch --flake .#macbook
```

### Home Manager

```bash
home-manager switch --flake .
```

## 🔧 Comandos Comunes

```bash
# Actualizar todas las entradas del flake
nix flake update

# Actualizar una entrada específica
nix flake update nixpkgs

# Verificar el flake en busca de errores
nix flake check

# Compilar desde el repositorio de GitHub
sudo nixos-rebuild switch --flake github:alex-bartleynees/nix-config#desktop
```

### Especializaciones

El host desktop incluye múltiples especializaciones de entorno de escritorio y temas:

```bash
# Cambiar entorno de escritorio
sudo nixos-rebuild switch --flake .#desktop --specialisation sway
sudo nixos-rebuild switch --flake .#desktop --specialisation niri
sudo nixos-rebuild switch --flake .#desktop --specialisation river
sudo nixos-rebuild switch --flake .#desktop --specialisation gnome
sudo nixos-rebuild switch --flake .#desktop --specialisation kde
sudo nixos-rebuild switch --flake .#desktop --specialisation cosmic
```

## 🎨 Características

### Módulos Principales

- **Gaming**: Transmisión de juegos con Steam, Sunshine y Moonlight
- **NVIDIA**: Controladores propietarios con soporte CUDA y offloading PRIME
- **Docker**: Runtime de contenedores con acceso de usuario
- **Tailscale**: Redes Mesh VPN
- **OpenRGB**: Control de iluminación RGB con desactivación opcional en inicio (`turnOffOnBoot`)
- **Stylix**: Temas a nivel de sistema
- **Impermanence**: Reinicio del sistema de archivos basado en BTRFS con persistencia selectiva

### Módulos (`modules/`)

Todos los archivos en `modules/` se importan automáticamente. El tipo de módulo se detecta por su estructura:

- **Módulos NixOS** (función simple): `backup`, `docker`, `gaming`, `impermanence`, `nvidia`, `openrgb`, `tailscale`, `voyager`, etc.
- **Módulos Home Manager** (`{ homeConfig = ...; }`): `git`, `shell`, `waybar`, `udiskie`, `awww`, `vicinae`, `ghostty`, `neovim`, `vscode`, etc.
- **Módulos combinados** (`{ nixosConfig = ...; homeConfig = ...; }`): `swayidle`, `hypridle` — manejan PAM a nivel de NixOS e inactividad/bloqueo a nivel de usuario en un solo archivo.

Módulos destacadas de Home Manager relacionados con el escritorio que son independientes del compositor y se vinculan a un objetivo de sesión:

- **swayidle**: Gestión de inactividad y bloqueo de pantalla; el módulo combinado también establece `security.pam.services.swaylock` a nivel de sistema
- **waybar**: Barra de estado con un servicio de usuario systemd opcional vinculado a un objetivo de sesión del compositor
- **udiskie**: Daemon de montaje automático como servicio de usuario systemd
- **awww**: Daemon de fondo de pantalla con fondo opcional al iniciar
- **vicinae**: Lanzador de aplicaciones como servicio de usuario systemd

Patrón de uso en archivos de escritorio:

```nix
swayidle = {
  enable = true;
  wallpaper = background;
  displayOffCommand = ''swaymsg "output * dpms off"'';
  displayOnCommand  = ''swaymsg "output * dpms on"'';
};

waybar.sessionTarget = "sway-session.target";
udiskie  = { enable = true; sessionTarget = "sway-session.target"; };
awww     = { enable = true; sessionTarget = "sway-session.target"; wallpaper = background; };
vicinae  = { enable = true; sessionTarget = "sway-session.target"; };
```

### Perfiles de Sistema

- **base**: Servicios centrales para todas las máquinas (Tailscale, Docker)
- **linux-desktop**: Sistema de escritorio con temas, impermanencia y servicios comunes de escritorio
- **gaming-workstation**: Escritorio de alto rendimiento con juegos, GPU NVIDIA e iluminación RGB
- **media-server**: Servidor multimedia con aceleración por hardware y enrutamiento de red
- **linux-laptop**: Gestión de energía para portátiles con TLP

Herencia de perfiles:

- `gaming-workstation` → `linux-desktop` → `base`
- `media-server` → `linux-desktop` → `base`
- `linux-laptop` → `linux-desktop` → `base`

### Entornos de Escritorio

- **Hyprland**: Compositor de mosaico dinámico (principal en desktop y media)
- **Sway**: Compositor de mosaico Wayland
- **Niri**: Compositor Wayland de mosaico desplazable (principal en thinkpad)
- **River**: Administrador de ventanas de mosaico eficiente
- **Mango** (`mangowc`): Compositor Wayland con diseños de scroll y master-stack
- **GNOME**: Escritorio GNOME completo con extensiones
- **KDE Plasma**: Experiencia KDE completa
- **Cosmic**: Entorno de escritorio basado en Rust de System76

### Aplicaciones

- Desarrollo: VSCode, JetBrains Rider, Neovim
- Terminal: Ghostty, Tmux
- Navegador: Brave con extensiones y temas declarativos
- Multimedia: Varios reproductores multimedia y códecs

### Perfiles de Home del Usuario

Los perfiles activan módulos automáticamente mediante el argumento `userProfiles`. Cada módulo se autodetalla con qué perfil lo activa:

| Perfil     | Activa                                                                                                               |
| ----------- | ----------------------------------------------------------------------------------------------------------------------- |
| `developer` | Neovim, shell (zsh/fish/nushell), git, direnv, distrobox, claude-code, opencode, lazygit, yazi y paquetes de desarrollo comunes |
| `vscode`    | VSCode con extensiones, atajos de teclado y configuraciones                                                                       |
| `rider`     | JetBrains Rider                                                                                                         |
| `backend`   | Cliente API Yaak                                                                                                         |
| `reader`    | Calibre                                                                                                                 |
| `work`      | Microsoft Teams, openfortivpn                                                                                           |

## 🔄 Impermanencia

Reinicio del sistema de archivos basado en BTRFS con persistencia selectiva:

```nix
impermanence = {
  enable = true;
  persistPaths = [
    "/etc/sops"
    "/etc/ssh"
    "/var/log"
    "/var/lib/nixos"
  ];
  resetSubvolumes = [ "@home" "@var" ];
  subvolumes = {
    "@home" = { mountpoint = "/home"; };
    "@var"  = { mountpoint = "/var"; };
  };
};
```

## 💾 Cifrado de Disco

Particionamiento de disco declarativo con [disko](https://github.com/nix-community/disko) y cifrado LUKS. Desktop y ThinkPad utilizan cifrado completo del disco con subvolúmenes BTRFS, comprimidos con zstd. El servidor multimedia utiliza discos sin cifrar por simplicidad.

## 🔐 Gestión de Secretos

[SOPS](https://github.com/Mic92/sops-nix) para secretos cifrados almacenados en `secrets/secrets.yaml`.

## 📦 Dependencias Clave

- **nixpkgs**: Repositorio principal de paquetes (nixos-unstable)
- **home-manager**: Gestión del entorno de usuario
- **nix-darwin**: Gestión del sistema macOS
- **nixos-wsl**: Integración con WSL
- **stylix**: Temas a nivel de sistema
- **sops-nix**: Gestión de secretos
- **disko**: Particionamiento de disco declarativo
- **nixos-hardware**: Configuraciones específicas de hardware
- **niri-flake**: Compositor Niri y paquetes
