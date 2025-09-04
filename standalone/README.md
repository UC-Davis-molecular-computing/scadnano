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

## Building

Building an executable for scadnano should be easy. Run the following commands for your respective platform.

> The executable will be located in `scadnano/standalone/dist`.

| **Platform** |     **Command**     |    **Executable Name**    |          **Cache**          |
|:------------:|:-------------------:|:-------------------------:|:---------------------------:|
|  *Windows*   | `npm run build:win` |   `scadnano X.X.X.exe`    | `C:/Users/<user>/.scadnano` |
|   *MacOS*    | `npm run build:mac` |   `scadnano-X.X.X.dmg`    |  `/Users/<user>/.scadnano`  |
|   *Ubuntu*   | `npm run build:lin` | `scadnano-X.X.X.AppImage` |  `/home/<user>/.scadnano`   |

> Note: If you are running into a symlink error on Windows when trying to build, you need to enable windows developer mode. You can do this by going to **Settings -> Privacy & Security -> For Developers** and turning on **Developer Mode**.

## Important Notes

### Exiting the App

You may need to `CTRL/CMD + C` from the command-line to exit the electron app.

### Creating a New Icon

To generate a new `icon.ico`, run something similar to the following command.

```shell
magick "../web/images/origami-icon-thin-seam-open-bottom.svg" -define icon:auto-resize=256,128,64,48,32 icon.ico
```

> You will need `magick` installed on your machine to do this.
