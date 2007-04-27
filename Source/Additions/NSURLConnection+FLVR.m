#import "NSURLConnection+FLVR.h"
#import "FLVRVideo.h"
#import "FLVRVideo+Private.h"
#import "FLVRVideoInterceptor.h"
#import "FLVRVideoInterceptor+Private.h"

@interface NSSynchronousURLConnectionDelegate
- (Class) class;
@end

#pragma mark -
@implementation NSURLConnection (FLVR)

- (id) FLVR_initWithRequest:(NSURLRequest*)request delegate:(id)delegate
{
#ifdef DEBUG
    NSLog(@"%@", request);
#endif
	if ([[[request URL] scheme] hasPrefix:@"http"] && ![delegate isKindOfClass:[NSSynchronousURLConnectionDelegate class]]) {
		return [self FLVR_initWithRequest:request delegate:[[[FLVRVideoInterceptor alloc] initWithDelegate:delegate] autorelease]];
	} else {
		return [self FLVR_initWithRequest:request delegate:delegate];
	}
}

- (void) FLVR_cancel
{
    FLVRVideoInterceptor* interceptor = [FLVRVideoInterceptor interceptorWithConnection:self];
    if (interceptor) {
        FLVRVideo* video = [interceptor _video];
        [FLVRVideoInterceptor unregisterInterceptorForConnection:self];
        if (video) {
            if ([video shouldAllowCancel]) {
                [video cancel];
                [self FLVR_cancel];
            } else {
                [interceptor _detachDelegate];
                [video _takeOwnershipOfConnection:self];
            }
        } else {
            [self FLVR_cancel];
        }
    } else {
        [self FLVR_cancel];
    }
}

@end