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