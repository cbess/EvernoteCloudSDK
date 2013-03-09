//
//  CBENOAuthViewController.m
//  EvernoteCloudDemo
//
//  Created by C. Bess on 1/12/13.
//  Copyright (c) 2013 C. Bess. All rights reserved.
//

#import "CBENOAuthViewController.h"

@interface CBENOAuthViewController ()

@end

@implementation CBENOAuthViewController

- (id)initWithAuthorizationURL:(NSURL *)authorizationURL oauthCallbackPrefix:(NSString *)oauthCallbackPrefix profileName:(NSString *)currentProfileName delegate:(id<ENOAuthViewControllerDelegate>)delegate
{
    self = [super initWithAuthorizationURL:authorizationURL
                       oauthCallbackPrefix:oauthCallbackPrefix
                               profileName:currentProfileName
                            allowSwitching:YES
                                  delegate:delegate];
    if (self)
    {
        // empty
    }
    return self;
}

- (void)dealloc
{
    self.webView.frameLoadDelegate = nil;
    self.webView.policyDelegate = self;
    [self.webView stopLoading:nil];
}

#pragma mark - Sheet

- (void)presentSheetForWindow:(NSWindow *)window
{
    [self.activityIndicator startAnimation:nil];
    
    // show the sheet
    [[NSApplication sharedApplication] beginSheet:self.view.window
                                   modalForWindow:window
                                    modalDelegate:self
                                   didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:)
                                      contextInfo:nil];
    
    [self updateUIForNewProfile:self.currentProfileName
           withAuthorizationURL:self.authorizationURL];
}

- (void)dismissSheet
{
    [[NSApplication sharedApplication] endSheet:self.view.window];
}

- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
    [sheet orderOut:nil];
}

#pragma mark - Events

- (IBAction)cancelButtonClicked:(id)sender
{
    [self dismissSheet];
    [self cancel:sender];
}

#pragma mark - WebView

- (void)webView:(WebView *)sender didClearWindowObject:(WebScriptObject *)windowObject forFrame:(WebFrame *)frame
{
    // adjust sheet height
//    id value = [windowObject evaluateWebScript:@"window.innerHeight"];
//    CBDebugLog(@"value: %@", value);
}

@end
