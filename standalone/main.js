const { app, BrowserWindow } = require('electron');
const path = require('path');

function createWindow() {
    const win = new BrowserWindow({
        width: 800,
        height: 600,
        webPreferences: {
            nodeIntegration: false // Security feature. Should be set to false for modern electron apps.
        },
    });

    const devPath = path.join(__dirname, '../build/index.html');
    const buildPath = path.join(__dirname, '../build/index.html');

    // win.loadURL((app.isPackaged) ? `file://${filePath}` : MAIN_WINDOW_WEBPACK_ENTRY);
    // win.loadURL((app.isPackaged) ? `file://${buildPath}` : `file://${devPath}`)

    // win.loadURL('file://' + path.join(__dirname, '../build/index.html'));

    win.loadFile((app.isPackaged) ? buildPath : devPath);

    // Uncomment to allow devtools (for debugging)
    // This is similar to Chrome DevTools. (Because it literally is chrome's devtools!)
    win.webContents.openDevTools();
}

app.whenReady().then(() => {
    createWindow();

    app.on('activate', () => {
        // MacOS. Re-open when clicked on dock.
        if (BrowserWindow.getAllWindows().length === 0) {
            createWindow();
        }
    });
});

app.on('window-all-closed', () => {
    if (process.platform !== 'darwin') {
        app.quit();
    }
});
