const { contextBridge } = require('electron');

let warnOnExit = false; // Store the value internally

contextBridge.exposeInMainWorld('electronAPI', {
    updateWarnOnExit: (value) => {
        console.log("Updating warnOnExit to:", value);
        warnOnExit = value; // Store the updated value
    },
    shouldWarnOnExit: () => {
        console.log("Checking warnOnExit:", warnOnExit);
        return warnOnExit; // Return the stored value
    }
});
