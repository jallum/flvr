#import <Cocoa/Cocoa.h>

@class FLVRVideo;

@interface FLVRVideoInterceptor : NSProxy {
    NSHTTPURLResponse* response;
    id delegate;
    FLVRVideo* video;
}

+ (FLVRVideoInterceptor*) interceptorWithConnection:(NSURLConnection*)urlConnection;
+ (void) unregisterInterceptorForConnection:(NSURLConnection*)connection;

- (id) initWithDelegate:(id)delegate;

@end
