//
//  	OverAppBrowser.h
//  	OverAppBrowser Cordova Plugin
//
//  	Copyright 2014 Emmanuel Tabard. All rights reserved.
//      MIT Licensed
//

#import <Cordova/CDVPlugin.h>


@interface OverAppBrowser : CDVPlugin <UIWebViewDelegate> {
	NSString* callbackId;
	UIWebView* overWebView;
    NSURL* currentUrl;
    BOOL _injectedIframeBridge;
}

@property (nonatomic, copy) NSString* callbackId;
@property (nonatomic, retain) UIWebView* overWebView;
@property (nonatomic, retain) NSURL* currentUrl;

@property (nonatomic, copy) NSRegularExpression *callbackIdPattern;


- (void)open:(CDVInvokedUrlCommand *)command;
- (void)fade:(CDVInvokedUrlCommand *)command;
- (void)resize:(CDVInvokedUrlCommand *)command;
- (void)injectScriptCode:(CDVInvokedUrlCommand*)command;
- (void)close:(CDVInvokedUrlCommand *)command;

@end
