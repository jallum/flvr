#import <Cocoa/Cocoa.h>

@interface NSURLConnection (FLVR) 

- (id) FLVR_initWithRequest:(NSURLRequest*)request delegate:(id)delegate;
- (void) FLVR_cancel;

@end
