# scadnano Standalone Application

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

| **Platform** |    **Command**     |    **Executable Name**    |      **Cache**       |
|:------------:|:------------------:|:-------------------------:|:--------------------:|
|  *Windows*   | `npm run buildWin` |   `scadnano X.X.X.exe`    | `%appdata%/scadnano` |
|   *MacOS*    | `npm run buildMac` |   `scadnano-X.X.X.dmg`    |        `TBD`         |
|   *Ubuntu*   | `npm run buildLin` | `scadnano-X.X.X.AppImage` |        `TBD`         |

## Important Notes

You may need to `CTRL/CMD + C` from the command-line to exit the electron app.
