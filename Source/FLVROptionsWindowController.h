#import <Cocoa/Cocoa.h>

@interface FLVROptionsWindowController : NSWindowController {
    IBOutlet NSPopUpButton* format;
    IBOutlet NSPopUpButton* videoCodec;
    IBOutlet NSPopUpButton* videoBitrate;
    IBOutlet NSPopUpButton* audioCodec;
    IBOutlet NSPopUpButton* audioBitrate;
    /**/
    NSMutableDictionary* options;
}

- (IBAction) cancel:(id)sender;
- (IBAction) close:(id)sender;
- (IBAction) changeDestinationFolder:(id)sender;
- (IBAction) resetDestinationFolder:(id)sender;

- (void) setSelectedFormat:(int)index;
- (int) selectedFormat;
- (void) setSelectedVideoCodec:(int)index;
- (int) selectedVideoCodec;
- (void) setSelectedAudioCodec:(int)index;
- (int) selectedAudioCodec;
- (void) setDestinationFolder:(NSString*)destinationFolder;
- (NSString*) destinationFolder;
- (void) setOptions:(NSDictionary*)options;
- (NSDictionary*) options;

@end
