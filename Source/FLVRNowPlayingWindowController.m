#import "FLVRNowPlayingWindowController.h"
#import "FLVRVideo.h"
#import "FLVRVideoCell.h"
#import "FLVRNowPlayingView.h"

NSString* FLVRNowPlayingOpenedNotification = \
    @"FLVRNowPlayingOpenedNotification";

@interface FLVRNowPlayingWindowController (Private)

- (void) _registeredVideo:(NSNotification*)notification;
- (void) _unregisteredVideo:(NSNotification*)notification;

@end

@implementation FLVRNowPlayingWindowController

- (void) awakeFromNib
{
    [betaVersion setStringValue:@"B12"];

    [[NSNotificationCenter defaultCenter] postNotificationName:FLVRNowPlayingOpenedNotification object:self];
    [nowPlayingView setVideos:[FLVRVideo registeredVideos]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_registeredVideo:) name:FLVRVideoRegisteredNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_unregisteredVideo:) name:FLVRVideoUnregisteredNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_progress:) name:FLVRVideoProgressNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_progress:) name:FLVRVideoEncodingNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_complete:) name:FLVRVideoCompleteNotification object:nil];
}

- (void) dealloc
{
    [nowPlayingView removeFromSuperview];
    [super dealloc];
}

- (IBAction) close:(id)sender
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [NSApp endSheet:[self window]];
}

- (IBAction) visitTasty:(id)sender
{
    [[
        [NSAppleScript alloc] initWithSource:
            [NSString stringWithFormat:
                @"tell application \"Safari\"\n"\
                "  make new document at end of documents\n"\
                "  set url of document 1 to \"http://www.tastyapps.com/\"\n"\
                "end tell\n"
            ]
        ]
        executeAndReturnError:nil
    ];
}

- (IBAction) clearCompleted:(id)sender
{
    NSEnumerator* e = [[FLVRVideo registeredVideos] objectEnumerator];
    FLVRVideo* video;
    while (video = [e nextObject]) {
        if ([video state] == FLVRVideoFinished) {
            [video cancel];
        }
    }
}

- (IBAction) clearAll:(id)sender
{
    NSEnumerator* e = [[FLVRVideo registeredVideos] objectEnumerator];
    FLVRVideo* video;
    while (video = [e nextObject]) {
        [video cancel];
    }
}

- (void) revealInFinder:(FLVRVideo*)video
{    
    [[NSWorkspace sharedWorkspace] selectFile:[video fullPathToEncodedFile] inFileViewerRootedAtPath:@""];
}

@end

@implementation FLVRNowPlayingWindowController (Private)

- (void) _registeredVideo:(NSNotification*)notification
{
    [nowPlayingView addVideo:[notification object]];
}

- (void) _unregisteredVideo:(NSNotification*)notification
{
    [nowPlayingView removeVideo:[notification object]];
}

- (void) _progress:(NSNotification*)notification
{
    [nowPlayingView updateCellForVideo:[notification object]];
}

- (void) _complete:(NSNotification*)notification
{
    [nowPlayingView updateCellForVideo:[notification object]];
}

@end