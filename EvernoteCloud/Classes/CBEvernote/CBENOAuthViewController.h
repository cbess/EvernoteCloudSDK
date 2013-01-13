//
//  CBENOAuthViewController.h
//  EvernoteCloudDemo
//
//  Created by C. Bess on 1/12/13.
//  Copyright (c) 2013 C. Bess. All rights reserved.
//

#import "ENOAuthViewController.h"

@interface CBENOAuthViewController : ENOAuthViewController

- (id)initWithAuthorizationURL:(NSURL *)authorizationURL oauthCallbackPrefix:(NSString *)oauthCallbackPrefix profileName:(NSString *)currentProfileName delegate:(id<ENOAuthViewControllerDelegate>)delegate;

- (void)presentSheet;
- (void)dismissSheet;

@end
