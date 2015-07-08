//	OverAppBrowser.js
//	OverAppBrowser Cordova Plugin
//
//
//  	Copyright 2014 Emmanuel Tabard. All rights reserved.
//      MIT Licensed
//


var exec = require('cordova/exec');
var channel = require('cordova/channel');
var modulemapper = require('cordova/modulemapper');
var urlutil = require('cordova/urlutil');

var inc = 10000;

function OverAppBrowser(strUrl, originx, originy, width, height, isAutoFadeIn) {
    var _this = this;

   this.channels = {
        'loadstart': channel.create('loadstart'),
        'loadstop' : channel.create('loadstop'),
        'loaderror' : channel.create('loaderror'),
        'exit' : channel.create('exit')
   };

   this.node = document.createElement("iframe"); 
   this.node.setAttribute("src", strUrl); 
   this.node.style.width = width+"px"; 
   this.node.style.height = height+"px"; 
   this.node.style.position = "absolute";
   this.node.style.top = originy + 'px';
   this.node.style.left = originx + 'px';
   this.node.style.zIndex = inc;
   this.node.style.transition = 'opacity 1s';
   this.node.style.opacity = 0;

   inc++;

   this.node.onload = function() {
    if (isAutoFadeIn) {
        _this.show();
    }
    _this._eventHandler({type: 'loadstop'});
   };
   window.setTimeout(function() {
    document.body.appendChild(_this.node);
    _this._eventHandler({type: 'loadstart'});
   },1);
}

OverAppBrowser.prototype = {
    _eventHandler: function (event) {
        console.log('fire event', event);
        if (event.type in this.channels) {
            this.channels[event.type].fire(event);
        }
    },
    close: function (eventname) {
        document.body.removeChild(this.node);
        this._eventHandler({type: 'exit'});
    },
    show: function (eventname) {
        this.node.style.transition = 'opacity 1s';
        this.node.style.opacity = 1;
    },
    fade: function (toAlpha, duration) {
        this.node.style.transition = 'opacity '+duration+'s';
        this.node.style.opacity = toAlpha;
    },
    resize: function (originx, originy, width, height) {
        this.node.style.width = width+"px"; 
        this.node.style.height = height+"px"; 
        this.node.style.top = originy + 'px';
        this.node.style.left = originx + 'px';
    },
    addEventListener: function (eventname,f) {
        if (eventname in this.channels) {
            this.channels[eventname].subscribe(f);
        }
    },
    removeEventListener: function(eventname, f) {
        if (eventname in this.channels) {
            this.channels[eventname].unsubscribe(f);
        }
    },

    executeScript: function(injectDetails, cb) {
         var node = document.createElement('script');
         node.type = "text/javascript";

        if (injectDetails.code) {
            node.innerHTML = injectDetails.code;
        } else if (injectDetails.file) {
            node.src = injectDetails.file;
        } else {
            throw new Error('executeScript requires exactly one of code or file to be specified');
        }

        if (node) {
            try {
                this.node.contentDocument.body.appendChild(node);
                cb && cb();
            } catch(e) {
                console.error(e);
            }
        }
    },

    insertCSS: function(injectDetails, cb) {
        var node;

        if (injectDetails.code) {
            node = document.createElement('style');
            node.innerHTML = injectDetails.code;
        } else if (injectDetails.file) {
            node = document.createElement('link');
            node.src = injectDetails.file;
        } else {
            throw new Error('insertCSS requires exactly one of code or file to be specified');
        }

        if (node) {
            try {
                this.node.contentDocument.body.appendChild(node);
                cb && cb();
            } catch(e) {
                console.error(e);
            }
        }
    }
};

module.exports = function(strUrl, originx,originy,width,height, isAutoFadeIn) {
    isAutoFadeIn = isAutoFadeIn || true;
    strUrl = urlutil.makeAbsolute(strUrl);
    var oab = new OverAppBrowser(strUrl, originx, originy, width, height, isAutoFadeIn);

    return oab;
};
