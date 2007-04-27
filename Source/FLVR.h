#import <Cocoa/Cocoa.h>

@interface FLVR : NSObject {
@private
    NSDictionary* parameters;
}

+ (FLVR*) sharedInstance;

- (void) showNowPlayingForWindow:(NSWindow*)window;

@end

#define FLVRLocalizedString(x, y)   [[NSBundle bundleForClass:[FLVR class]] localizedStringForKey:x value:x table:nil]
