## Evernote for Mac (Built on top of the Evernote SDK for iOS)

Forked from [Evernote SDK for iOS version 1.0.1](https://github.com/evernote/evernote-sdk-ios/commit/b5e932581b069257350efff8f4de19b3706e51ed).

100% compatible with [Evernote SDK for iOS](https://github.com/evernote/evernote-sdk-ios).

## Demo Setup

1. Provide API info in `CBMainWindow.m`
1. Start the app
1. Click `Sync` button

## Usage

To implement in your own Mac desktop app:

1. Copy `CBEvernote` folder to your project
1. Copy `evernote` folder to your project
1. Add `CBEvernote.h` to your header

### Change Notes

I made as few changes as possible to make this as maintainable as possible. It should require very little work when the iOS SDK is updated. The largest change was adding the Mac OAuth view controller workflow.

Changed files:

1. EvernoteSession.*
1. ENOAuthViewController.*

I also added some **sample code to list notebooks and notes**.

The code within this SDK is compatible with both the Mac (tested) and iOS (untested) platforms.

### Purpose

I saw no good Evernote Mac examples and the Evernote iOS SDK was about 90% compatible with Cocoa/AppKit.

License
-------

[BSD](http://opensource.org/licenses/BSD-2-Clause) = I hope its helpful.
