#import "FLVRNowPlayingPanel.h"
#import "FLVRNowPlayingPanelThemeFrame.h"

@interface NSWindow (Private)
+ (Class) frameViewClassForStyleMask:(unsigned int)mask;
@end

@interface FLVRNowPlayingPanel (Private)
- (void) setupAppearance;
@end

@implementation FLVRNowPlayingPanel

+ (Class) frameViewClassForStyleMask:(unsigned int)styleMask
{
	return [FLVRNowPlayingPanelThemeFrame class];
}

- (void) keyDown:(NSEvent*)event
{
    NSString *chars = [event characters];
    unichar character = [chars characterAtIndex: 0];

    if (character == 27 && [[self delegate] respondsToSelector:@selector(close:)]) {
        [[self delegate] close:nil];
    } else {
        [super keyDown:event];
    }
}

@end
