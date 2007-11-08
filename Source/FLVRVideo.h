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