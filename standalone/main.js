const { app, BrowserWindow, dialog } = require('electron');
const path = require('path');
const os = require('os');

app.setPath('userData', path.join(os.homedir(), '.scadnano/data'));
app.setPath('cache', path.join(os.homedir(), '.scadnano/cache'));

let win;

function createWindow() {
    win = new BrowserWindow({
        width: 800,
        height: 600,
        webPreferences: {
            nodeIntegration: false, // Security feature. Keep it false.
            contextIsolation: true,
            preload: path.join(__dirname, 'preload.js') // Preload script
        },
    });

    win.loadFile(path.join(__dirname, '../build/index.html'));

    // DEBUG: Uncomment to allow devtools for debugging
    // win.webContents.openDevTools();

    // Handle close event
    win.on('close', async (event) => {
        const shouldWarn = await win.webContents.executeJavaScript('window.warnOnExit || false');

        if (shouldWarn) {
            event.preventDefault(); // Stop the window from closing
            const result = await dialog.showMessageBox(win, {
                type: 'warning',
                buttons: ['Cancel', 'Exit'],
                defaultId: 0,
                message: 'You have unsaved changes. Are you sure you want to exit?',
            });

            if (result.response === 1) { // "Exit" clicked
                win.destroy(); // Allow closing
            }
        }
    });
}

app.whenReady().then(() => {
    createWindow();

    app.on('activate', () => {
        // MacOS: Re-open when clicked on dock.
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
