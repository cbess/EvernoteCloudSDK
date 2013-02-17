//
//  CBEMainWindow.m
//  EvernoteCloud
//
//  Created by C. Bess on 1/11/13.
//  Copyright (c) 2013 C. Bess. All rights reserved.
//

#import "CBEMainWindow.h"
#import "EvernoteSDK.h"

static NSString * const kConsumerAPIKeyKey = @"consumer-key";
static NSString * const kConsumerAPISecretKey = @"consumer-secret";

@interface CBEMainWindow () <NSTableViewDataSource, NSTableViewDelegate>

@property (weak) IBOutlet NSTextField *noteNameTextField;
@property (unsafe_unretained) IBOutlet NSTextView *noteBodyTextView;
@property (weak) IBOutlet NSTextField *notebookLabel;
@property (assign) IBOutlet NSButton *syncButton;
@property (weak) IBOutlet NSButton *createNoteButton;
@property (weak) IBOutlet NSButton *sendNoteButton;
@property (strong) IBOutlet NSTableView *tableView;
@property (weak) IBOutlet NSTextField *footerLabel;

@property (nonatomic, strong) NSMutableArray *notebooks;
@property (nonatomic, strong) NSMutableArray *notes;
@property (nonatomic, strong) EDAMNotebook *selectedNotebook;

@end

@implementation CBEMainWindow

#pragma mark - Misc

- (void)reloadTable
{
    [self.tableView reloadData];
}

- (void)fetchAllNotesWithNotebookGUID:(EDAMGuid)guid
{
    // filter for all notes in the notebook with the specified GUID
    EDAMNoteFilter* noteFilter = [[EDAMNoteFilter alloc] initWithOrder:0
                                                             ascending:NO
                                                                 words:nil
                                                          notebookGuid:guid
                                                              tagGuids:nil
                                                              timeZone:nil
                                                              inactive:NO
                                                            emphasized:nil];
    // get the notebook notes
    EvernoteNoteStore *noteStore = [EvernoteNoteStore noteStore];
    [noteStore findNotesWithFilter:noteFilter offset:0 maxNotes:INT16_MAX success:^(EDAMNoteList *list) {
        self.notes = list.notes;
        CBDebugLog(@"got %lu notes", self.notes.count);
        
        // update UI
        [self reloadTable];
    } failure:^(NSError *error) {
        CBDebugLog(@"error: %@", error);
    }];
}

- (void)fetchNotebooks
{
    // grab the notebooks
    [[EvernoteNoteStore noteStore] listNotebooksWithSuccess:^(NSArray *notebooks) {
        // store the notebooks
        self.notebooks = [NSMutableArray arrayWithArray:notebooks];
        
        // store first notebook
        EDAMNotebook *notebook = notebooks[0];
        self.selectedNotebook = notebook;
        CBDebugLog(@"notebooks: %@", notebooks);
        
        self.notebookLabel.stringValue = notebook.name;
        
        // ultimately updates the table view
        [self fetchAllNotesWithNotebookGUID:notebook.guid];
    } failure:^(NSError *error) {
        CBDebugLog(@"error %@", error);
    }];
}

- (EDAMNote *)newNoteWithTitle:(NSString *)title contents:(NSString *)contents
{
    // convert plain-text to valid evernote contents
    NSString *noteContent = [self evernoteContentStringWithContents:contents];
    
    // providing attributes to make read-only, and add other meta info
    // http://dev.evernote.com/documentation/cloud/chapters/read_only_notes.php
    EDAMNoteAttributes *attrs = [[EDAMNoteAttributes alloc] initWithSubjectDate:0
                                                                       latitude:0
                                                                      longitude:0
                                                                       altitude:0
                                                                         author:@"dev-author"
                                                                         source:nil
                                                                      sourceURL:nil
                                                              sourceApplication:nil
                                                                      shareDate:0
                                                                      placeName:nil
                                                                   contentClass:@"dev.evernotecloud.sdk" // make readonly
                                                                applicationData:nil
                                                                   lastEditedBy:nil
                                                                classifications:nil];
    // create the note from the input text
    EDAMNote *note = [[EDAMNote alloc] initWithGuid:nil
                                              title:title
                                            content:noteContent
                                        contentHash:nil
                                      contentLength:(int)noteContent.length
                                            created:0
                                            updated:0
                                            deleted:0
                                             active:YES
                                  updateSequenceNum:0
                                       notebookGuid:self.selectedNotebook.guid // add to selected notebook
                                           tagGuids:nil
                                        // https://github.com/evernote/evernote-sdk-ios/blob/master/SampleApp/iPhoneViewController.m#L149
                                          resources:nil // use resources to add attachments to the note
                                         attributes:attrs
                                           tagNames:nil];
    return note;
}

- (NSString *)stringFromDate:(NSDate *)date
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateStyle = NSDateFormatterShortStyle;
    formatter.timeStyle = NSDateFormatterMediumStyle;
    return [formatter stringFromDate:date];
}

// ref: http://dev.evernote.com/documentation/local/chapters/enml.php
- (NSString *)evernoteContentStringWithContents:(NSString *)contents
{
    // replace the blank/empty lines
    contents = [contents stringByReplacingOccurrencesOfString:@"\n\n" withString:@"<div><br /></div>\n"];
    
    // wrap new lines
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^(.*)$"
                                                                           options:NSRegularExpressionAnchorsMatchLines
                                                                             error:nil];
    NSString *noteContents = [regex stringByReplacingMatchesInString:contents
                                                             options:0
                                                               range:NSMakeRange(0, contents.length)
                                                        withTemplate:@"<div>$1</div>"];
    // build enml string
    return [NSString stringWithFormat:
     @"<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
     "<!DOCTYPE en-note SYSTEM \"http://xml.evernote.com/pub/enml2.dtd\">"
     "<en-note>"
     "%@"
     "</en-note>",
     noteContents];
}

#pragma mark - Events

- (IBAction)syncButtonClicked:(id)sender
{
    // set up Evernote session singleton
    NSString *authPath = [[NSBundle mainBundle] pathForResource:@"evernote-auth.plist" ofType:nil];
    NSDictionary *consumerInfo = [NSDictionary dictionaryWithContentsOfFile:authPath];
    [EvernoteSession setSharedSessionHost:BootstrapServerBaseURLStringSandbox
                              consumerKey:consumerInfo[kConsumerAPIKeyKey]
                           consumerSecret:consumerInfo[kConsumerAPISecretKey]];
    
    // no-op view controller to satisfy the iOS portion of the SDK
    NSViewController *viewController = [NSViewController new];
    
    EvernoteSession *session = [EvernoteSession sharedSession];
    [session authenticateWithViewController:viewController completionHandler:^(NSError *error) {
        if (error || !session.isAuthenticated)
        {
            CBDebugLog(@"NOT authenticated: %@", error);
            NSRunAlertPanel(@"Authorization", @"Evernote access denied.", @"OK", nil, nil);
        }
        else
        {
            CBDebugLog(@"authenticated! noteStoreUrl:%@ webApiUrlPrefix:%@", session.noteStoreUrl, session.webApiUrlPrefix);
            CBDebugLog(@"fetching note information...");
            
            if (self.selectedNotebook == nil)
                NSRunAlertPanel(@"Authorization", @"Evernote access allowed. Press OK to fetch note information.", @"OK", nil, nil);
            
            [self fetchNotebooks];
            
            // update ui
            self.footerLabel.stringValue = [self stringFromDate:[NSDate date]];
            [self.createNoteButton setEnabled:YES];
            [self.syncButton setTitle:@"Refresh"];
        }
    }];
}

// 'new note' pressed
- (IBAction)createNoteButtonPressed:(id)sender
{
    self.noteNameTextField.stringValue = @"";
    self.noteBodyTextView.string = @"";
    
    [self.noteNameTextField setEnabled:YES];
    [self.noteBodyTextView setEditable:YES];
    
    [self makeFirstResponder:self.noteNameTextField];
    [self.sendNoteButton setEnabled:YES];
}

- (IBAction)sendNoteButtonPressed:(id)sender
{
    EDAMNote *note = [self newNoteWithTitle:self.noteNameTextField.stringValue
                                   contents:self.noteBodyTextView.string];
    // send the note to evernote
    [[EvernoteNoteStore noteStore] createNote:note success:^(EDAMNote *note) {
        [self createNoteButtonPressed:nil]; // clear note fields
        NSRunAlertPanel(@"Send Note", @"Note saved and sent to Evernote.", @"OK", nil, nil);
    } failure:^(NSError *error) {
        CBDebugLog(@"error: %@", error);
    }];
}

#pragma mark - TableView

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    EDAMNote *note = self.notes[row];
    
    if ([tableColumn.identifier isEqualToString:@"name"])
        return note.title;
    else if ([tableColumn.identifier isEqualToString:@"date"])
        return [self stringFromDate:[NSDate dateWithTimeIntervalSince1970:note.updated]];
    
    return nil;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    if (!self.notes)
        return 0;
    
    return self.notes.count;
}

@end
