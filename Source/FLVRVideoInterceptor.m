/* FLVR -- Flash Video Ripper
 * Copyright (C) 2007 Jason Allum
 * 
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, 
 * USA.
 */
#import "FLVRVideoInterceptor.h"
#import "FLVRVideoInterceptor+Private.h"
#import "FLVRVideo.h"
#import "FLVRVideo+Private.h"

@implementation FLVRVideoInterceptor

static NSLock* lock;
static NSMutableDictionary* registry;

+ (void) initialize
{
    if (self == [FLVRVideoInterceptor class]) {
        lock = [[NSLock alloc] init];
        registry = [[NSMutableDictionary alloc] initWithCapacity:10];
    }
}

+ (FLVRVideoInterceptor*) interceptorWithConnection:(NSURLConnection*)urlConnection
{
    [lock lock];
    FLVRVideoInterceptor* value = [registry objectForKey:[urlConnection description]];
    [lock unlock];
    return value;
}

+ (void) registerInterceptor:(FLVRVideoInterceptor*)interceptor forConnection:(NSURLConnection*)connection
{
    [lock lock];
    [registry setObject:interceptor forKey:[connection description]];
    [lock unlock];
}

+ (void) unregisterInterceptorForConnection:(NSURLConnection*)connection
{
    [lock lock];
    [registry removeObjectForKey:[connection description]];
    [lock unlock];
}

//  ------------------------------------------------------------------------

- (id) initWithDelegate:(id)_delegate
{
    delegate = [_delegate retain];
    return self;
}

- (void) dealloc
{
    [response release];
    [delegate release];
    [video release];
    [super dealloc];
}

- (BOOL) respondsToSelector:(SEL)selector
{
    if (selector == @selector(connection:didCancelAuthenticationChallenge:) 
     || selector == @selector(connection:didFailWithError:) 
     || selector == @selector(connection:didReceiveAuthenticationChallenge:) 
     || selector == @selector(connection:didReceiveData:) 
     || selector == @selector(connection:didReceiveData:lengthReceived:)
     || selector == @selector(connection:didReceiveResponse:) 
     || selector == @selector(connection:willCacheResponse:) 
     || selector == @selector(connection:willSendRequest:redirectResponse:) 
     || selector == @selector(connection:willStopBufferingData:)
     || selector == @selector(connectionDidFinishLoading:)
    ) {
        return [delegate respondsToSelector:selector];
    } else {
        return [super respondsToSelector:selector];
    }
}

- (NSMethodSignature*) methodSignatureForSelector:(SEL)selector
{
    NSLog(@"%@", NSStringFromSelector(selector));
    return [delegate methodSignatureForSelector:selector];
}

- (void) forwardInvocation:(NSInvocation*)invocation
{
    NSLog(@"%@", invocation);
    [invocation invokeWithTarget:delegate];
    return;
}

- (void) connection:(NSURLConnection*)connection didCancelAuthenticationChallenge:(NSURLAuthenticationChallenge*)challenge
{
    [delegate connection:connection didCancelAuthenticationChallenge:challenge];
}

- (void) connection:(NSURLConnection*)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge*)challenge
{
    [delegate connection:connection didReceiveAuthenticationChallenge:challenge];
}

- (void) connection:(NSURLConnection*)connection didReceiveData:(NSData*)data
{
    if (response) {
        [self _attemptToCaptureConnection:connection withData:data];
        [response release];
        response = nil;
    }
    if (video) {
        [video _processData:data];
    }
    [delegate connection:connection didReceiveData:data];
}

- (void) connection:(NSURLConnection*)connection didReceiveData:(NSData*)data lengthReceived:(long long)length
{
    if (response) {
        [self _attemptToCaptureConnection:connection withData:data];
        [response release];
        response = nil;
    }
    if (video) {
        [video _processData:data];
    }
    [delegate connection:connection didReceiveData:data lengthReceived:length];
}

- (void) connection:(NSURLConnection*)connection willStopBufferingData:(NSData*)data
{
    [delegate connection:connection willStopBufferingData:data];
}

- (void) connection:(NSURLConnection*)connection didReceiveResponse:(NSURLResponse*)_response
{
    response = [_response retain];
    [delegate connection:connection didReceiveResponse:response];
}

- (NSCachedURLResponse*) connection:(NSURLConnection*)connection willCacheResponse:(NSCachedURLResponse*)cachedResponse
{
    return [delegate connection:connection willCacheResponse:cachedResponse];
}

- (NSURLRequest*) connection:(NSURLConnection*)connection willSendRequest:(NSURLRequest*)request redirectResponse:(NSURLResponse*)redirectResponse
{
    return [delegate connection:connection willSendRequest:request redirectResponse:redirectResponse];
}

- (void) connection:(NSURLConnection*)connection didFailWithError:(NSError*)error
{
    if (video) {
        [FLVRVideoInterceptor unregisterInterceptorForConnection:connection];
        [video cancel];
    }
    [delegate connection:connection didFailWithError:error];
}

- (void) connectionDidFinishLoading:(NSURLConnection*)connection
{
    if (video) {
        [FLVRVideoInterceptor unregisterInterceptorForConnection:connection];
        [video _complete];
    }
    [delegate connectionDidFinishLoading:connection];
}

@end

@implementation FLVRVideoInterceptor (Private)

static unsigned char MAGIC_FLV_V1[] = {
    0x46, 0x4c, 0x56, 0x01
};

static unsigned char MAGIC_RM[] = {
    0x2e, 0x52, 0x4d, 0x46
};

#ifdef DEBUG
static unsigned char MAGIC_WMV[] = {
    0x30, 0x26, 0xB2, 0x75, 
    0x8E, 0x66, 0xCF, 0x11,
    0xA6, 0xD9, 0x00, 0xAA,
    0x00, 0x62, 0xCE, 0x6C
};
#endif

- (void) _attemptToCaptureConnection:(NSURLConnection*)connection withData:(NSData*)data
{
    char* bytes = (void*)[data bytes];
    NSString* type = nil;
    
    /*  Based on the first tiny bit of the file, try and figure out whether 
     *  this is a video that we want try to capture, or not.
     */ 
    if ([data length] >= sizeof(MAGIC_FLV_V1) && (0 == memcmp(bytes, MAGIC_FLV_V1, sizeof(MAGIC_FLV_V1)))) {
        if ([data length] >= 9) {
            /*  Some videos do not report their audio tracks, even though they
             *  are there.  This screws up FFMPEG, which pays attention to 
             *  these bits, and will ignore audio if they are not set properly.
             */
//            bytes[0x04] |= 5;
        } 
        type = @"flv";
    } else if ([data length] >= sizeof(MAGIC_RM) && (0 == memcmp(bytes, MAGIC_RM, sizeof(MAGIC_RM)))) {
        type = @"rm";
#ifdef DEBUG
    } else if ([data length] >= sizeof(MAGIC_WMV) && (0 == memcmp(bytes, MAGIC_WMV, sizeof(MAGIC_WMV)))) {
        type = @"asf";
#endif
    }
    
    /*  If it's one of the types we support, capture it.
     */
    if (type) {
        if (video = [[FLVRVideo alloc] initWithType:type response:response interceptor:self]) {
            [FLVRVideoInterceptor registerInterceptor:self forConnection:connection];
        }
    }
}

- (void) _detachDelegate
{
    id _delegate = delegate;
    delegate = nil;
    [_delegate release];
}

- (void) _detachVideo
{
    id _video = video;
    video = nil;
    [_video release];
}

- (FLVRVideo*) _video
{
    return [[video retain] autorelease];
}

@end