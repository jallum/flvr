#import "BrowserWindowController+FLVR.h"
#import "FLVRNowPlayingPanel.h"

@implementation BrowserWindowController (FLVR)

- (NSRect) FLVR_notPresent_window:(NSWindow*)window willPositionSheet:(NSWindow*)sheet usingRect:(NSRect)rect 
{
    return rect;
}

- (NSRect) FLVR_window:(NSWindow*)window willPositionSheet:(NSWindow*)sheet usingRect:(NSRect)r1 
{
    NSRect r2 = [self FLVR_window:window willPositionSheet:sheet usingRect:r1];
    if (NSEqualRects(r1, r2) && ([sheet isKindOfClass:[FLVRNowPlayingPanel class]] || [sheet class] == [NSPanel class])) {
        r2.origin.y -= 31;
    }
    return r2;
}

@end
