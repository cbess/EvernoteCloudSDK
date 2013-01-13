//
//  ENOAuthViewController.h
//  evernote-sdk-ios
//
//  Created by Matthew McGlincy on 5/26/12.
//  Copyright (c) 2012 n/a. All rights reserved.
//

#if IS_MAC
#import <WebKit/WebKit.h>
#endif

@class ENOAuthViewController;

typedef IF_MAC(WebView, UIWebView) CBEWebView;

@protocol ENOAuthViewControllerDelegate <NSObject>
- (void)oauthViewControllerDidCancel:(ENOAuthViewController *)sender;
- (void)oauthViewControllerDidSwitchProfile:(ENOAuthViewController *)sender;
- (void)oauthViewController:(ENOAuthViewController *)sender didFailWithError:(NSError *)error;
- (void)oauthViewController:(ENOAuthViewController *)sender receivedOAuthCallbackURL:(NSURL *)url;
@end

@interface ENOAuthViewController : IF_MAC(NSViewController, UIViewController)

@property (nonatomic, strong) IBOutlet CBEWebView *webView;
@property (nonatomic, strong) IBOutlet IF_MAC(NSProgressIndicator, UIActivityIndicatorView) *activityIndicator;
@property (nonatomic, strong) NSURL *authorizationURL;
@property (nonatomic, copy) NSString *currentProfileName;

@property (nonatomic, weak) id<ENOAuthViewControllerDelegate> delegate;

- (id)initWithAuthorizationURL:(NSURL *)authorizationURL
           oauthCallbackPrefix:(NSString *)oauthCallbackPrefix
                   profileName:(NSString *)currentProfileName
                allowSwitching:(BOOL)isSwitchingAllowed
                      delegate:(id<ENOAuthViewControllerDelegate>)delegate;

- (void)updateUIForNewProfile:(NSString*)newProfile withAuthorizationURL:(NSURL*)authURL;

- (void)loadWebView;
- (void)cancel:(id)sender;

@end
