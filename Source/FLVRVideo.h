#import <Cocoa/Cocoa.h>

@class FLVRVideoInterceptor;

@interface FLVRVideo : NSObject {
    NSURLConnection* connection;
    NSHTTPURLResponse* response;
    FLVRVideoInterceptor* interceptor;
    NSString* type;
    /**/
    long long expectedContentLength;
    int fileHandleForReading;
    int fileHandleForWriting;
    int fileHandleForWritingToCodec;
    NSMutableData* firstFrameBuffer;
    /**/
    int pidForCodec;
    int pidForSed;
    /**/
    NSMutableDictionary* info;
    NSImage* firstFrame;
    float percentDownloaded;
    float percentEncoded;
    enum {
        FLVRVideoCheck,
        FLVRVideoDownloading,
        FLVRVideoEncoding,
        FLVRVideoFinished,
    } state;
    NSString* filename;
    BOOL willEncode;
    /**/
    NSString* fullPathToEncodedFile;
    NSString* fullPathToTempFile;
}

+ (void) registerVideo:(FLVRVideo*)video;
+ (void) unregisterVideo:(FLVRVideo*)video;
+ (NSArray*) registeredVideos;

- (id) initWithType:(NSString*)type response:(NSHTTPURLResponse*)response interceptor:(FLVRVideoInterceptor*)interceptor;

- (NSString*) filename;
- (void) setFilename:(NSString*)filename;

- (int) state;
- (float) percentDownloaded;
- (float) percentEncoded;
- (BOOL) shouldAllowCancel;
- (NSImage*) firstFrame;
- (NSDictionary*) info;
- (NSString*) fullPathToEncodedFile;

- (void) beginEncoding;
- (void) cancel;

@end

extern NSString* FLVRVideoRegisteredNotification;
extern NSString* FLVRVideoUnregisteredNotification;
extern NSString* FLVRVideoProgressNotification;
extern NSString* FLVRVideoEncodingNotification;
extern NSString* FLVRVideoCompleteNotification;