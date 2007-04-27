
@interface FLVRVideoInterceptor (Private)

- (void) _attemptToCaptureConnection:(NSURLConnection*)connection withData:(NSData*)data;
- (void) _detachDelegate;
- (void) _detachVideo;
- (FLVRVideo*) _video;

@end
