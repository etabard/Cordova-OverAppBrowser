OverAppBrowser 1.1
==================

Render a webview over your cordova webview.

Installation
------------

To install from **command line**:

    cordova plugin add com.lesfrancschatons.cordova.plugins.overappbrowser


Documentation
-------------

	//function(strUrl, originx, originy, width, height, isAutoFadeIn)
    oab = new OverAppBrowser('http://www.google.fr', 0, 100, 320, 320, true);
    oab.addEventListener('loadstop', function(){
			oab.insertCSS({code:'#hplogoo {-webkit-transform: rotate(180deg);}'});
    });

    //Fade the webview
    oab.fade(toAlpha, duration);

    //Resize the webview
    oab.resize(originx, originy, width, height);

    //Close the webview
    oab.close();


This loads google.fr over your html app at x=0, y=100, width=320, height=320 and rotates the homepage logo
