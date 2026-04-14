# scadnano Standalone Application

If you have not yet already, please read the main [README.md](../README.md).

## Downloading and installing the executable

**You do not need to build anything to run scadnano offline.** Pre-built executables are published on GitHub:

- **Latest release (stable):** https://github.com/UC-Davis-molecular-computing/scadnano/releases/latest
- **Latest dev build (prerelease):** https://github.com/UC-Davis-molecular-computing/scadnano/releases/tag/dev-latest

Follow the instructions for your platform below.

### Windows

1. Download `scadnano-win-x64.exe` (most PCs) or `scadnano-win-arm64.exe` (ARM-based PCs, e.g. some Surface devices).
2. Double-click the downloaded `.exe` to run. No installation step is required.
3. Windows SmartScreen may show a warning because the executable is not yet code-signed. Click **"More info"** → **"Run anyway"**. We are in the process of getting the binary signed to remove this warning in future releases.

### macOS

1. Download `scadnano-mac-universal.dmg` (works on both Intel and Apple Silicon Macs).
2. Double-click the `.dmg` and drag the `scadnano` app into your **Applications** folder.
3. Because the app is not yet signed by Apple, macOS will refuse to open it until you remove the quarantine flag. Open Terminal and run:
   ```shell
   sudo xattr -rd com.apple.quarantine /Applications/scadnano.app
   ```
4. Launch `scadnano` from Applications or Spotlight.

### Linux

Three package formats are provided. **Pick one** based on your distribution and preference:

- **AppImage (recommended if you don't want to install — runs on any Linux distro).**
  1. Download `scadnano-linux-x86_64.AppImage` (most PCs) or `scadnano-linux-arm64.AppImage` (ARM64, e.g. Raspberry Pi 4+).
  2. Make it executable and run:
     ```shell
     chmod +x scadnano-linux-x86_64.AppImage
     ./scadnano-linux-x86_64.AppImage
     ```
  3. If you get an error about `libfuse.so.2`, install FUSE:
     - Debian/Ubuntu: `sudo apt install libfuse2`
     - Fedora: `sudo dnf install fuse-libs`

- **`.deb` (Debian, Ubuntu, Linux Mint, etc.).**
  1. Download `scadnano-linux-amd64.deb` (x86_64) or `scadnano-linux-arm64.deb` (ARM64).
  2. Install:
     ```shell
     sudo dpkg -i scadnano-linux-amd64.deb
     ```
  3. Launch from your application menu or run `scadnano` from the terminal.

- **`.rpm` (Fedora, RHEL, openSUSE, etc.).**
  1. Download `scadnano-linux-x86_64.rpm` (x86_64) or `scadnano-linux-aarch64.rpm` (ARM64).
  2. Install:
     ```shell
     sudo rpm -i scadnano-linux-x86_64.rpm
     ```
  3. Launch from your application menu or run `scadnano` from the terminal.

---

The rest of this document describes how to **build** the executable from source, which is only needed if you
are contributing to scadnano or want to run a locally modified version.

## Development

To run the development version of scadnano standalone, run the following commands in the `scadnano/standalone` directory.

```shell
npm install
```

```shell
npm run dev
```

### Generating Icons (Not Required)

To generate icons for the Development build, run the following commands on your specific platform.

**Windows**

```shell
sh .\generate-icons.sh ../web/images/origami-icon-thin-seam.png
```

**Linux/MacOS**
```shell
chmod +x ./generate-icons.sh
./generate-icons.sh ../web/images/origami-icon-thin-seam.png
```

> You must have imagemagick installed for all platforms.

> For MacOS, you must also have iconutil installed.

## Building

Building an executable for scadnano should be easy. Run the following commands for your respective platform.

> The executable will be located in `scadnano/standalone/dist`.

| **Platform** |     **Command**     |   **Executable Name**   |          **Cache**          |
|:------------:|:-------------------:|:-----------------------:|:---------------------------:|
|  *Windows*   | `npm run build:win` |  `scadnano-<ARCH>.exe`  | `C:/Users/<user>/.scadnano` |
|   *MacOS*    | `npm run build:mac` |  `scadnano-<ARCH>.dmg`  |  `/Users/<user>/.scadnano`  |
|   *Linux*    | `npm run build:lin` | `scadnano-<ARCH>.<EXT>` |  `/home/<user>/.scadnano`   |

> Note: If you are running into a symlink error on Windows when trying to build, you need to enable windows developer mode. You can do this by going to **Settings -> Privacy & Security -> For Developers** and turning on **Developer Mode**.

## Uninstalling

- **Windows / AppImage users:** delete the downloaded executable file, then delete the cache directory (`C:/Users/<user>/.scadnano` on Windows, `/home/<user>/.scadnano` on Linux).
- **macOS:** drag `scadnano` from Applications to the Trash, then delete `/Users/<user>/.scadnano`.
- **`.deb` install (Debian/Ubuntu):** `sudo dpkg -r scadnano`, then delete `/home/<user>/.scadnano`.
- **`.rpm` install (Fedora/RHEL):** `sudo rpm -e scadnano`, then delete `/home/<user>/.scadnano`.

## Important Notes

### Exiting the App

You may need to `CTRL/CMD + C` from the command-line to exit the electron app when running in development mode.
