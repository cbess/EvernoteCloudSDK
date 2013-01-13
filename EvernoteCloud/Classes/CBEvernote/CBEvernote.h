//
//  CBEvernote.h
//  EvernoteCloud
//
//  Created by C. Bess on 1/11/13.
//  Copyright (c) 2013 C. Bess. All rights reserved.
//

#ifndef EvernoteCloud_CBEvernote_h
#define EvernoteCloud_CBEvernote_h

#ifdef __IPHONE_OS_VERSION_MAX_ALLOWED
#   define IS_IOS 1
#   define IF_MAC(T_BLOCK, F_BLOCK) F_BLOCK
#else
#   define IS_MAC 1
#   define IF_MAC(T_BLOCK, F_BLOCK) T_BLOCK
#endif

#ifdef IS_IOS
#import <UIKit/UIKit.h>
#else
#import <Cocoa/Cocoa.h>
#endif

#import "CBMacros.h"

#endif
