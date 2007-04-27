#import <Cocoa/Cocoa.h>

@class FLVRVideo;

@interface FLVRVideoCell : NSTextFieldCell {
    int tag;
    NSImage* thumbnail;
    NSImage* reflection;
    /**/
    NSButtonCell* revealButton;
    NSButtonCell* encodeButton;
    NSButtonCell* cancelButton;
    NSTextFieldCell* filenameCell;
    NSTextFieldCell* durationCell;
    NSTextFieldCell* videoInfoCell;
    NSTextFieldCell* audioInfoCell;
}

+ (NSImage*) buildThumbnailFromImage:(NSImage*)image;

@end
