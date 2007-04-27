#import <Cocoa/Cocoa.h>

@interface FLVRVideo (Private)

- (void) _complete;
- (void) _processData:(NSData*)data;
- (void) _takeOwnershipOfConnection:(NSURLConnection*)_connection;

- (void) _launchEncodingTask;
- (int) _launchCodecTask;
- (void) _killTasks;

@end