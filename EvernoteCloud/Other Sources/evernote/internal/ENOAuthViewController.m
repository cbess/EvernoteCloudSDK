//
//  ENOAuthViewController.m
//  evernote-sdk-ios
//
//  Created by Matthew McGlincy on 5/26/12.
//  Copyright (c) 2012 n/a. All rights reserved.
//

#import "ENOAuthViewController.h"
#import "ENConstants.h"

#if IS_MAC
@interface ENOAuthViewController()
#else
@interface ENOAuthViewController() <UIWebViewDelegate>
#endif

@property (nonatomic, strong) NSString *oauthCallbackPrefix;
@property (nonatomic, assign) BOOL isSwitchingAllowed;

@end

@implementation ENOAuthViewController

@synthesize delegate = _delegate;
@synthesize authorizationURL = _authorizationURL;
@synthesize oauthCallbackPrefix = _oauthCallbackPrefix;
@synthesize webView = _webView;

- (void)dealloc
{
#if IS_IOS
    self.webView.delegate = nil;
    [self.webView stopLoading];
#endif
}

- (id)initWithAuthorizationURL:(NSURL *)authorizationURL
           oauthCallbackPrefix:(NSString *)oauthCallbackPrefix
                   profileName:(NSString *)currentProfileName
                allowSwitching:(BOOL)isSwitchingAllowed
                      delegate:(id<ENOAuthViewControllerDelegate>)delegate
{
#if IS_IOS
    self = [super init];
#else
    self = [super initWithNibName:NSStringFromClass(self.class) bundle:nil];
#endif
    
    if (self) {
        self.authorizationURL = authorizationURL;
        self.oauthCallbackPrefix = oauthCallbackPrefix;
        self.currentProfileName = currentProfileName;
        self.delegate = delegate;
        self.isSwitchingAllowed = isSwitchingAllowed;
    }
    return self;
}

#if IS_IOS
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIBarButtonItem *cancelItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel", @"Cancel") style:UIBarButtonItemStylePlain target:self action:@selector(cancel:)];
    
    self.navigationItem.rightBarButtonItem = cancelItem;
    
    // adding an activity indicator
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [self.activityIndicator setHidesWhenStopped:YES];
    
    self.webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
    self.webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.webView.scalesPageToFit = YES;
    self.webView.delegate = self;
    [self.view addSubview:self.webView];
    self.activityIndicator.frame = CGRectMake((self.navigationController.view.frame.size.width - (self.activityIndicator.frame.size.width/2))/2,
                                              (self.navigationController.view.frame.size.height - (self.activityIndicator.frame.size.height/2) - 44)/2,
                                              self.activityIndicator.frame.size.width,
                                              self.activityIndicator.frame.size.height);
    [self.webView addSubview:self.activityIndicator];
    [self updateUIForNewProfile:self.currentProfileName
           withAuthorizationURL:self.authorizationURL];
}
#endif

- (void)cancel:(id)sender
{
    [self.webView IF_MAC(stopLoading:nil, stopLoading)];
    if (self.delegate) {
        [self.delegate oauthViewControllerDidCancel:self];
    }
    self.delegate = nil;
}

#if IS_IOS
- (void)switchProfile:(id)sender
{
    [self.webView stopLoading];
    // start a page flip animation
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
    [UIView setAnimationDuration:1.0];
    [UIView setAnimationTransition:UIViewAnimationTransitionFlipFromLeft
                           forView:[[self navigationController] view]
                             cache:YES];    
    [self.webView setDelegate:nil];
    // Blank out the web view
    [self.webView stringByEvaluatingJavaScriptFromString:@"document.open();document.close()"];
    self.navigationItem.leftBarButtonItem = nil;
    [UIView commitAnimations];
}
#endif

- (void)animationDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context {
    [self.activityIndicator IF_MAC(startAnimation:nil, startAnimating)];
    [self.delegate oauthViewControllerDidSwitchProfile:self];
}

- (void)updateUIForNewProfile:(NSString*)newProfile withAuthorizationURL:(NSURL*)authURL{
    self.authorizationURL = authURL;
    self.currentProfileName = newProfile;
    
#if IS_IOS
    if(self.isSwitchingAllowed) {
        NSString *leftButtonTitle = nil;
        if([self.currentProfileName isEqualToString:ENBootstrapProfileNameChina]) {
            leftButtonTitle = NSLocalizedString(@"Evernote-International", @"Evernote-International");
        }
        else {
            leftButtonTitle = NSLocalizedString(@"Evernote-China", @"Evernote-China");
        }
        UIBarButtonItem* switchProfileButton = [[UIBarButtonItem alloc] initWithTitle:leftButtonTitle style:UIBarButtonItemStylePlain target:self action:@selector(switchProfile:)];
        self.navigationItem.leftBarButtonItem = switchProfileButton;
    }
#endif
    
    [self loadWebView];
}

- (void)loadWebView {
#if IS_IOS
    [self.activityIndicator startAnimating];
    [self.webView setDelegate:self];
    [self.webView loadRequest:[NSURLRequest requestWithURL:self.authorizationURL]];
#else
    [self.activityIndicator startAnimation:nil];
    self.webView.frameLoadDelegate = self;
    self.webView.policyDelegate = self;
    [self.webView.mainFrame loadRequest:[NSURLRequest requestWithURL:self.authorizationURL]];
#endif
}

#if IS_IOS
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}
#endif

# pragma mark - WebView Delegate

- (void)webView:(CBEWebView *)webView didFailLoadWithError:(NSError *)error
{
    [self.activityIndicator IF_MAC(stopAnimation:nil, stopAnimating)];
    if ([error.domain isEqualToString:@"WebKitErrorDomain"] && error.code == 102) {
        // ignore "Frame load interrupted" errors, which we get as part of the final oauth callback :P
        return;
    }
    
    if (error.code == NSURLErrorCancelled) {
        // ignore rapid repeated clicking (error code -999)
        return;
    }
    
    [self.webView IF_MAC(stopLoading:nil, stopLoading)];

    if (self.delegate) {
        [self.delegate oauthViewController:self didFailWithError:error];
    }
}

#if IS_MAC
- (void)webView:(WebView *)sender didStartProvisionalLoadForFrame:(WebFrame *)frame
{
    [self webView:sender shouldStartLoadWithRequest:frame.dataSource.request];
}

// handles redirects, which is used by OAuth
- (void)webView:(WebView *)webView decidePolicyForNavigationAction:(NSDictionary *)actionInformation request:(NSURLRequest *)request frame:(WebFrame *)frame decisionListener:(id < WebPolicyDecisionListener >)listener
{
    if ([[request.URL absoluteString] hasPrefix:self.oauthCallbackPrefix])
    {
        // this is our OAuth callback prefix, so let the delegate handle it
        if (self.delegate)
        {
            [self.delegate oauthViewController:self receivedOAuthCallbackURL:request.URL];
        }
        
        [listener ignore];
    }
    else
    {
        // perform default action
        [listener use];
    }
}

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame
{
    [self webViewDidFinishLoad:sender];
}
#endif

#if IS_IOS
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
#else
- (BOOL)webView:(WebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request
#endif
{
    if ([[request.URL absoluteString] hasPrefix:self.oauthCallbackPrefix]) {
        // this is our OAuth callback prefix, so let the delegate handle it
        if (self.delegate) {
            [self.delegate oauthViewController:self receivedOAuthCallbackURL:request.URL];
        }
        return NO;
    }
    return YES;
}

- (void)webViewDidFinishLoad:(CBEWebView *)webView {
    [self.activityIndicator IF_MAC(stopAnimation:nil, stopAnimating)];
}

@end
