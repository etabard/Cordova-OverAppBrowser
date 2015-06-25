//
//      OverAppBrowser.m
//      OverAppBrowser Cordova Plugin
//
//      Copyright 2014 Emmanuel Tabard. All rights reserved.
//      MIT Licensed
//

#import "OverAppBrowser.h"
#import <Cordova/CDVJSON.h>

@implementation OverAppBrowser

@synthesize overWebView, callbackId, currentUrl;


-(CDVPlugin*) initWithWebView:(UIWebView*)theWebView
{
    self = (OverAppBrowser*)[super initWithWebView:theWebView];
    
    if (self != nil) {
        _callbackIdPattern = nil;
    }

    return self;
}


#pragma mark -
#pragma mark OverAppBrowser

- (void) open:(CDVInvokedUrlCommand *)command
{
    NSArray* arguments = [command arguments];
    
    self.callbackId = command.callbackId;
    NSUInteger argc = [arguments count];
    
    if (argc < 4) { // at a minimum we need x origin, y origin and width...
        return; 
    }
    
    if (self.overWebView != NULL) {
        [self browserExit]; // reload it as parameters may have changed
    }
    
    CGFloat originx,originy,width;
    CGFloat height = 30;
    NSString *url = [arguments objectAtIndex:0];
    originx = [[arguments objectAtIndex:1] floatValue];
    originy = [[arguments objectAtIndex:2] floatValue];
    width = [[arguments objectAtIndex:3] floatValue];
    if (argc > 3) {
        height = [[arguments objectAtIndex:4] floatValue];
    }
    if (argc > 4) {
        isAutoFadeIn = [[arguments objectAtIndex:5] boolValue];
    }
    
    CGRect viewRect = CGRectMake(
                                 originx, 
                                 originy, 
                                 width, 
                                 height
                                 );

  self.overWebView = [[UIWebView alloc] initWithFrame:viewRect];
  NSURL *nsurl=[NSURL URLWithString:url];
  NSURLRequest *nsrequest=[NSURLRequest requestWithURL:nsurl];

  [self.overWebView loadRequest:nsrequest];
  self.overWebView.backgroundColor = [UIColor clearColor];
  self.overWebView.scrollView.bounces = NO;
  self.overWebView.clearsContextBeforeDrawing = YES;
  self.overWebView.clipsToBounds = YES;
    self.overWebView.delegate = self;
  self.overWebView.contentMode = UIViewContentModeScaleToFill;
  self.overWebView.multipleTouchEnabled = YES;
  self.overWebView.opaque = NO;
  self.overWebView.scalesPageToFit = NO;
  self.overWebView.userInteractionEnabled = YES;
    
    self.overWebView.alpha = 0;
    
    

  [self.webView.superview addSubview:self.overWebView];

}

- (void)fade:(CDVInvokedUrlCommand *)command {
    NSArray* arguments = [command arguments];
    NSUInteger argc = [arguments count];
    
    if (argc < 2) {
        return;
    }
    [self fadeToAlpha:[[arguments objectAtIndex:0] floatValue] duration:[[arguments objectAtIndex:1] floatValue]];
}

- (void)fadeToAlpha:(float)alpha duration:(float)duration {
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration: alpha];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    [self.overWebView setAlpha: duration];
    [UIView commitAnimations];
}

- (void)resize:(CDVInvokedUrlCommand *)command {
    NSArray* arguments = [command arguments];
    
    NSUInteger argc = [arguments count];
    
    if (argc < 3) { // at a minimum we need x origin, y origin and width...
        return;
    }
    
    if (self.overWebView == NULL) {
        return; // not yet created
    }
    
    CGFloat originx,originy,width;
    CGFloat height = 30;
    originx = [[arguments objectAtIndex:0] floatValue];
    originy = [[arguments objectAtIndex:1] floatValue];
    width = [[arguments objectAtIndex:2] floatValue];
    if (argc > 3) {
        height = [[arguments objectAtIndex:3] floatValue];
    }
    
    CGRect viewRect = CGRectMake(
                                 originx,
                                 originy,
                                 width,
                                 height
                                 );
    
    self.overWebView.frame = viewRect;
}

- (BOOL)isValidCallbackId:(NSString *)callbackId
{
    NSError *err = nil;
    // Initialize on first use
    if (self.callbackIdPattern == nil) {
        self.callbackIdPattern = [NSRegularExpression regularExpressionWithPattern:@"^OverAppBrowser[0-9]{1,10}$" options:0 error:&err];
        if (err != nil) {
            // Couldn't initialize Regex; No is safer than Yes.
            return NO;
        }
    }
    if ([self.callbackIdPattern firstMatchInString:callbackId options:0 range:NSMakeRange(0, [callbackId length])]) {
        return YES;
    }
    return NO;
}

/**
 * The iframe bridge provided for the InAppBrowser is capable of executing any oustanding callback belonging
 * to the InAppBrowser plugin. Care has been taken that other callbacks cannot be triggered, and that no
 * other code execution is possible.
 *
 * To trigger the bridge, the iframe (or any other resource) should attempt to load a url of the form:
 *
 * gap-iab://<callbackId>/<arguments>
 *
 * where <callbackId> is the string id of the callback to trigger (something like "InAppBrowser0123456789")
 *
 * If present, the path component of the special gap-iab:// url is expected to be a URL-escaped JSON-encoded
 * value to pass to the callback. [NSURL path] should take care of the URL-unescaping, and a JSON_EXCEPTION
 * is returned if the JSON is invalid.
 */
- (BOOL)webView:(UIWebView*)theWebView shouldStartLoadWithRequest:(NSURLRequest*)request navigationType:(UIWebViewNavigationType)navigationType
{
    NSURL* url = request.URL;
    BOOL isTopLevelNavigation = [request.URL isEqual:[request mainDocumentURL]];
    
    if (isTopLevelNavigation) {
        self.currentUrl = request.URL;
    }
    
    // See if the url uses the 'gap-iab' protocol. If so, the host should be the id of a callback to execute,
    // and the path, if present, should be a JSON-encoded value to pass to the callback.
    if ([[url scheme] isEqualToString:@"gap-iab"]) {
        NSString* scriptCallbackId = [url host];
        CDVPluginResult* pluginResult = nil;
        
        if ([self isValidCallbackId:scriptCallbackId]) {
            NSString* scriptResult = [url path];
            NSError* __autoreleasing error = nil;
            
            // The message should be a JSON-encoded array of the result of the script which executed.
            if ((scriptResult != nil) && ([scriptResult length] > 1)) {
                scriptResult = [scriptResult substringFromIndex:1];
                NSData* decodedResult = [NSJSONSerialization JSONObjectWithData:[scriptResult dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:&error];
                if ((error == nil) && [decodedResult isKindOfClass:[NSArray class]]) {
                    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:(NSArray*)decodedResult];
                } else {
                    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_JSON_EXCEPTION];
                }
            } else {
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:@[]];
            }
            [self.commandDelegate sendPluginResult:pluginResult callbackId:scriptCallbackId];
            return NO;
        }
    } else if ((self.callbackId != nil) && isTopLevelNavigation) {
        // Send a loadstart event for each top-level navigation (includes redirects).
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                                      messageAsDictionary:@{@"type":@"loadstart", @"url":[url absoluteString]}];
        [pluginResult setKeepCallback:[NSNumber numberWithBool:YES]];
        
        [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callbackId];
    }
    
    return YES;
}

- (void)webViewDidStartLoad:(UIWebView*)theWebView
{
    _injectedIframeBridge = NO;
}

- (void)webViewDidFinishLoad:(UIWebView*)theWebView
{
    if (self.overWebView.isLoading) {
        return;
    }
    if (self.callbackId != nil && self.currentUrl != nil) {
        if (isAutoFadeIn) {
            [self fadeToAlpha:1 duration:1.0];
        }
        
        // TODO: It would be more useful to return the URL the page is actually on (e.g. if it's been redirected).
        NSString* url = [self.currentUrl absoluteString];
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                                      messageAsDictionary:@{@"type":@"loadstop", @"url":url}];
        [pluginResult setKeepCallback:[NSNumber numberWithBool:YES]];
        
        [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callbackId];
    }
}


// This is a helper method for the inject{Script|Style}{Code|File} API calls, which
// provides a consistent method for injecting JavaScript code into the document.
//
// If a wrapper string is supplied, then the source string will be JSON-encoded (adding
// quotes) and wrapped using string formatting. (The wrapper string should have a single
// '%@' marker).
//
// If no wrapper is supplied, then the source string is executed directly.

- (void)injectDeferredObject:(NSString*)source withWrapper:(NSString*)jsWrapper
{
    if (!_injectedIframeBridge) {
        _injectedIframeBridge = YES;
        // Create an iframe bridge in the new document to communicate with the CDVInAppBrowserViewController
        [self.overWebView stringByEvaluatingJavaScriptFromString:@"(function(d){var e = _cdvIframeBridge = d.createElement('iframe');e.style.display='none';d.body.appendChild(e);})(document)"];
    }
    
    if (jsWrapper != nil) {
        NSString* sourceArrayString = [@[source] JSONString];
        if (sourceArrayString) {
            NSString* sourceString = [sourceArrayString substringWithRange:NSMakeRange(1, [sourceArrayString length] - 2)];
            NSString* jsToInject = [NSString stringWithFormat:jsWrapper, sourceString];
            [self.overWebView stringByEvaluatingJavaScriptFromString:jsToInject];
        }
    } else {
        [self.overWebView stringByEvaluatingJavaScriptFromString:source];
    }
}

- (void)injectScriptCode:(CDVInvokedUrlCommand*)command
{
    NSString* jsWrapper = nil;
    
    if ((command.callbackId != nil) && ![command.callbackId isEqualToString:@"INVALID"]) {
        jsWrapper = [NSString stringWithFormat:@"_cdvIframeBridge.src='gap-iab://%@/'+encodeURIComponent(JSON.stringify([eval(%%@)]));", command.callbackId];
    }
    [self injectDeferredObject:[command argumentAtIndex:0] withWrapper:jsWrapper];
}

- (void)injectScriptFile:(CDVInvokedUrlCommand*)command
{
    NSString* jsWrapper;
    
    if ((command.callbackId != nil) && ![command.callbackId isEqualToString:@"INVALID"]) {
        jsWrapper = [NSString stringWithFormat:@"(function(d) { var c = d.createElement('script'); c.src = %%@; c.onload = function() { _cdvIframeBridge.src='gap-iab://%@'; }; d.body.appendChild(c); })(document)", command.callbackId];
    } else {
        jsWrapper = @"(function(d) { var c = d.createElement('script'); c.src = %@; d.body.appendChild(c); })(document)";
    }
    [self injectDeferredObject:[command argumentAtIndex:0] withWrapper:jsWrapper];
}

- (void)injectStyleCode:(CDVInvokedUrlCommand*)command
{
    NSString* jsWrapper;
    
    if ((command.callbackId != nil) && ![command.callbackId isEqualToString:@"INVALID"]) {
        jsWrapper = [NSString stringWithFormat:@"(function(d) { var c = d.createElement('style'); c.innerHTML = %%@; c.onload = function() { _cdvIframeBridge.src='gap-iab://%@'; }; d.body.appendChild(c); })(document)", command.callbackId];
    } else {
        jsWrapper = @"(function(d) { var c = d.createElement('style'); c.innerHTML = %@; d.body.appendChild(c); })(document)";
    }
    [self injectDeferredObject:[command argumentAtIndex:0] withWrapper:jsWrapper];
}

- (void)injectStyleFile:(CDVInvokedUrlCommand*)command
{
    NSString* jsWrapper;
    
    if ((command.callbackId != nil) && ![command.callbackId isEqualToString:@"INVALID"]) {
        jsWrapper = [NSString stringWithFormat:@"(function(d) { var c = d.createElement('link'); c.rel='stylesheet'; c.type='text/css'; c.href = %%@; c.onload = function() { _cdvIframeBridge.src='gap-iab://%@'; }; d.body.appendChild(c); })(document)", command.callbackId];
    } else {
        jsWrapper = @"(function(d) { var c = d.createElement('link'); c.rel='stylesheet', c.type='text/css'; c.href = %@; d.body.appendChild(c); })(document)";
    }
    [self injectDeferredObject:[command argumentAtIndex:0] withWrapper:jsWrapper];
}

- (void) dealloc
{
    [self browserExit];
}

- (void)close:(CDVInvokedUrlCommand *)command
{
    [self browserExit];
}

- (void) browserExit
{
    if (self.callbackId != nil) {
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                                      messageAsDictionary:@{@"type":@"exit"}];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callbackId];
        self.callbackId = nil;
    }
    
    [self.overWebView loadHTMLString:@"" baseURL:nil];
    [self.overWebView stopLoading];
    [self.overWebView setDelegate:nil];
    [self.overWebView removeFromSuperview];
    self.overWebView = nil;
    self.currentUrl = nil;
}



@end
