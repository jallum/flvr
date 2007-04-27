#import <Cocoa/Cocoa.h>

@interface FLVRPulseButton : NSButton {
    NSTimer* timer;
    NSImage* originalImage;
    NSMutableArray* images;
    int index;
    int direction;
}

- (IBAction) startPulsing:(id)sender;
- (IBAction) stopPulsing:(id)sender;

@end
