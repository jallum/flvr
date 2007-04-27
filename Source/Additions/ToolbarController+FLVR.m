#import "ToolbarController+FLVR.h"
#import "FLVR.h"
#import "FLVRVideo.h"
#import "FLVRPulseButton.h"
#import "FLVRNowPlayingWindowController.h"

@implementation ToolbarController (FLVR)

- (IBAction) FLVR_hook:(id)sender
{
    NSWindow* window = [[NSApplication sharedApplication] keyWindow];
    if ([window isKindOfClass:[BrowserWindow class]]) {
        [[FLVR sharedInstance] showNowPlayingForWindow:window];
    }
}

- (BrowserToolbarItem*) FLVR_toolbar:(BrowserToolbar*)toolbar itemForItemIdentifier:(NSString*)identifier willBeInsertedIntoToolbar:(BOOL)flag
{
    if ([@"FLVR" isEqualTo:identifier]) {
        FLVRPulseButton* button = [[FLVRPulseButton alloc] initWithFrame:NSMakeRect(0, 0, 28, 25)];
        [button setTitle:@"FLVR"];
        [button setToolTip:FLVRLocalizedString(@"FLVR - Download Flash Video", @"")];
        [button setBordered:NO];
        [button setButtonType:NSMomentaryChangeButton];
        [button setImage:[[[NSImage alloc] initByReferencingFile:[[NSBundle bundleForClass:[FLVR class]] pathForResource:@"Toolbar" ofType:@"png"]] autorelease]];
        [button setAlternateImage:[[[NSImage alloc] initByReferencingFile:[[NSBundle bundleForClass:[FLVR class]] pathForResource:@"ToolbarPressed" ofType:@"png"]] autorelease]];
        [button setAction:@selector(FLVR_hook:)];
        [button setKeyEquivalent:@"n"];
        [button setKeyEquivalentModifierMask:NSAlternateKeyMask | NSCommandKeyMask];
        [[NSNotificationCenter defaultCenter] addObserver:button selector:@selector(startPulsing:) name:FLVRVideoRegisteredNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:button selector:@selector(stopPulsing:) name:FLVRNowPlayingOpenedNotification object:nil];
        return [[BrowserToolbarItem alloc] initWithItemIdentifier:@"FLVR" target:self button:button];
    } else {
        BrowserToolbarItem* item = [self FLVR_toolbar:toolbar itemForItemIdentifier:identifier willBeInsertedIntoToolbar:flag];
        return item;
    }
}

- (NSArray*) FLVR_toolbarAllowedItemIdentifiers:(BrowserToolbar*)toolbar
{
    NSMutableArray* items = [NSMutableArray arrayWithArray:[self FLVR_toolbarAllowedItemIdentifiers:toolbar]];
    [items addObject:@"FLVR"];
    return items;
}

@end
