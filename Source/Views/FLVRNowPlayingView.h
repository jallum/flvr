#import <Cocoa/Cocoa.h>

@class FLVRVideo;

@interface FLVRNowPlayingView : NSMatrix {
    int trackingTag;
    int cellTrackingTag;
    int mouseOverTag;
    /**/
    NSMutableArray* videos;
}

- (void) setVideos:(NSArray*)videos;
- (void) addVideo:(FLVRVideo*)video;
- (void) removeVideo:(FLVRVideo*)video;
- (void) updateCellForVideo:(FLVRVideo*)video;

@end

@interface NSObject (FLVRNowPlayingViewDelegate)
- (void) revealInFinder:(FLVRVideo*)video;
@end