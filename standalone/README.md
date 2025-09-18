# scadnano Standalone Application

If you have not yet already, please read the main [README.md](../README.md).

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

## Installing

Installing should be as simple as just running the downloaded `exe`/`dmg`/`AppImage`. However, there is a special command you need to run for MacOS in order to be able to run the app.

* MacOS: After installing, from the terminal, run this command:

```shell
sudo xattr -rd com.apple.quarantine /Applications/scadnano.app
```

From here, you should be able to run the application normally.

## Uninstalling

To uninstall, simply delete the executable file and the **cache** directory in the above table based on the operating system you are using.

## Important Notes

### Exiting the App

You may need to `CTRL/CMD + C` from the command-line to exit the electron app.
