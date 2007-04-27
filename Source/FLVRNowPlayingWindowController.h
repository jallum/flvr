#import <Cocoa/Cocoa.h>

@class FLVRNowPlayingView;

@interface FLVRNowPlayingWindowController : NSWindowController {
    IBOutlet FLVRNowPlayingView* nowPlayingView;
    IBOutlet NSTextField* betaVersion;
}

- (IBAction) close:(id)sender;
- (IBAction) visitTasty:(id)sender;
- (IBAction) clearCompleted:(id)sender;
- (IBAction) clearAll:(id)sender;

@end

extern NSString* FLVRNowPlayingOpenedNotification;
