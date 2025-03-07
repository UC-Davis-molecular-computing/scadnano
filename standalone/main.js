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

    win.loadFile(path.join(__dirname, '../build/index.html'));

    // Uncomment to allow devtools (for debugging)
    // This is similar to Chrome DevTools. (Because it literally is chrome's devtools!)
    // win.webContents.openDevTools();
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
