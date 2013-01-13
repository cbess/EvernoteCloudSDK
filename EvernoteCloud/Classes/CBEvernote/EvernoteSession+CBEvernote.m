//
//  EvernoteSession+CBEvernote.m
//  EvernoteCloudDemo
//
//  Created by C. Bess on 1/12/13.
//  Copyright (c) 2013 C. Bess. All rights reserved.
//

#import "EvernoteSession+CBEvernote.h"
#import "CBENOAuthViewController.h"

@implementation EvernoteSession (CBEvernote)

- (void)dismissViewController
{
#if IS_IOS
    [self.viewController dismissModalViewControllerAnimated:YES];
#else
    CBENOAuthViewController *authVC = (CBENOAuthViewController*) self.oauthViewController;
    [authVC dismissSheet];
#endif
}

@end
