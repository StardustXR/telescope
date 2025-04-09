# telescope
See the stars! Telescope is a bundled installation for the linux XR display server **Stardust XR**, that includes the [Stardust XR Server](https://github.com/StardustXR/server), [Hexagon Launcher](https://github.com/StardustXR/protostar), [Flatland](https://github.com/StardustXR/flatland), and [Black Hole](https://github.com/StardustXR/black-hole)

This is the easiest way to quickly experience what Stardust XR has to offer!

> [!NOTE]
> For help with setting up an XR headset on linux, visit https://stardustxr.org/docs/get-started/setup-openxr

## Installation
The [Terra repository is required](https://terra.fyralabs.com/). If you're using [Ultramarine Linux](https://ultramarine-linux.org), this comes pre-installed, otherwise Standard Fedora Editions and derivatives can directly install terra-release:
```bash
sudo dnf install --nogpgcheck --repofrompath 'terra,https://repos.fyralabs.com/terra$releasever' terra-release
```
Then install Telescope using:
```bash
sudo dnf install telescope
```

On Arch Linux, Stardust XR is available in the Arch Linux User Repository [AUR](https://aur.archlinux.org/packages/stardust-xr-telescope). We suggest using an [AUR helper](https://wiki.archlinux.org/title/AUR_helpers), like Paru:
```
paru -S stardust-xr-telescope
```
<h1>
  <img src="/img/docs/nixos.svg" alt="Logo" style={{ verticalAlign: 'middle', height: '1em', marginRight: '0.5em' }} />
  NixOS 
</h1>

On NixOS, use the [Nix package manager](https://nixos.org/download/#nix-install-linux) Make sure [flakes are enabled](https://nixos.wiki/wiki/flakes).

```
nix run github:StardustXR/telescope
```
# After Installation
From here, just run `telescope -f` for flatscreen mode in your terminal! 

You will see a floating hexagon with the Stardust XR logo in the center, this is Hexagon Launcher.
To move around, hold down ***Shift*** and ***W A S D***, with ***Q*** for moving down and ***E*** for moving up.  
![WASD Q E Look around](/img/updated_flat_wasd.GIF)

To look around, hold down ***Shift*** and ***Right Click*** while moving the mouse.  
![Look around](/img/updated_flat_look.GIF)

If you click on the hexagon, the launcher will open. Try dragging one of the apps with `Shift + ~`. The small minus sign is Black Hole, if you click it, it will grab any open window and store it away. Click it again and they will return to their original location.  
![Flat drag](/img/updated_flat_drag.GIF)

If you are already using OpenXR within Linux, running `telescope` while OpenXR is running should launch Stardust on your headset. If not, check further instructions for setting up OpenXR.
