## Our efforts worked

As of v1.1.1, Evernote SDK is Mac/iOS compatible:

- [Mac SDK](https://github.com/evernote/evernote-sdk-mac)
- [Install Mac SDK](https://github.com/evernote/evernote-sdk-mac/blob/master/INSTALL-MAC.md)

Please use the SDK links above.

## Evernote for Mac (Built on top of the Evernote SDK for iOS)

![image](https://raw.github.com/cbess/EvernoteCloudSDK/master/screenshot.jpg)

Forked from [Evernote SDK for iOS version 1.0.1](https://github.com/evernote/evernote-sdk-ios/commit/b5e932581b069257350efff8f4de19b3706e51ed).

100% compatible with [Evernote SDK for iOS](https://github.com/evernote/evernote-sdk-ios).

## Demo Setup

1. Provide API info:
  1. Add `evernote-auth.plist` to your project (ignored by git)
  2. Add *consumer-key* string under *Root*, value = your consumer key
  3. Add *consumer-secret* string under *Root*, value = your consumer key
1. Start the app
1. Click `Sync` button

## Usage

To implement in your own Mac desktop app:

1. Copy `CBEvernote` folder to your project.
1. Copy `evernote` folder to your project.
1. Add `CBEvernote.h` to your header (in the PCH or where needed). 
 
See sample project for more guidance.

### Change Notes

I made as few changes as possible to make this as maintainable as possible. It should require very little work when the iOS SDK is updated. The largest change was adding the Mac OAuth view controller workflow.

Changed files:

1. EvernoteSession.*
1. ENOAuthViewController.*

I also added some **sample code to list notebooks and notes**.

The code within this SDK is compatible with both the Mac (tested) and iOS (untested) platforms.

## Purpose

I saw no good Evernote Mac examples and the Evernote iOS SDK was about 90% compatible with Cocoa/AppKit.

License
-------

[BSD](http://opensource.org/licenses/BSD-2-Clause) = I hope its helpful.
