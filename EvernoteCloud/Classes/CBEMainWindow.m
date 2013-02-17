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
@property (strong) IBOutlet NSTableView *tableView;

//@property (nonatomic, strong) NSMutableArray *notebooks;
@property (nonatomic, strong) NSMutableArray *notes;

@end

@implementation CBEMainWindow

#pragma mark - Misc

- (void)reloadTable
{
    [self.tableView reloadData];
}

- (void)fetchAllNotesWithNotebookGUID:(EDAMGuid)guid
{
    EvernoteNoteStore *defaultNoteStore = [EvernoteNoteStore noteStore];
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
    [defaultNoteStore findNotesWithFilter:noteFilter offset:0 maxNotes:INT16_MAX success:^(EDAMNoteList *list) {
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
    EvernoteNoteStore *noteStore = [EvernoteNoteStore noteStore];
    [noteStore listNotebooksWithSuccess:^(NSArray *notebooks) {
        EDAMNotebook *notebook = notebooks[0];
        CBDebugLog(@"notebooks: %@", notebooks);
        
        self.notebookLabel.stringValue = notebook.name;
        
        // ultimately updates the table view
        [self fetchAllNotesWithNotebookGUID:notebook.guid];
    } failure:^(NSError *error) {
        CBDebugLog(@"error %@", error);
    }];
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
            
            NSRunAlertPanel(@"Authorization", @"Evernote access allowed. Press OK to fetch note information.", @"OK", nil, nil);
            
            [self fetchNotebooks];
        }
    }];
}

// 'new note' pressed
- (IBAction)addNoteButtonPressed:(id)sender
{
    self.noteNameTextField.stringValue = @"";
    self.noteBodyTextView.string = @"";
    
    [self makeFirstResponder:self.noteNameTextField];
}

- (IBAction)saveNoteButtonPressed:(id)sender
{
    
}

#pragma mark - TableView

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    EDAMNote *note = self.notes[row];
    
    if ([tableColumn.identifier isEqualToString:@"name"])
        return note.title;
    else if ([tableColumn.identifier isEqualToString:@"date"])
        return [NSDate dateWithTimeIntervalSince1970:note.created];
    
    return nil;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    if (!self.notes)
        return 0;
    
    return self.notes.count;
}

@end
