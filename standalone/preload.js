const { contextBridge } = require('electron');

let warnOnExit = false; // Store the value internally

contextBridge.exposeInMainWorld('electronAPI', {
    updateWarnOnExit: (value) => {
        warnOnExit = value; // Store the updated value
    },
    shouldWarnOnExit: () => {
        return warnOnExit; // Return the stored value
    }
});
