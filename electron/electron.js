// Titlebar
const customTitlebar = require('custom-electron-titlebar');

let Titlebar = new customTitlebar.Titlebar({
    backgroundColor: customTitlebar.Color.fromHex('#ffffff'),
    icon: './images/app_icon.svg',
    titleHorizontalAlignment: 'left',
});

Titlebar.updateTitle('RAWRS');

window.document.querySelector(".container-after-titlebar").style.display = "flex";
window.document.querySelector(".container-after-titlebar").style.flexDirection = "column";
window.document.querySelector(".window-title").style.fontFamily = "Lato";
