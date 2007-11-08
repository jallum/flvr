/* FLVR -- Flash Video Ripper
 * Copyright (C) 2007 Jason Allum
 * 
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, 
 * USA.
 */
#import "FLVR.h"
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