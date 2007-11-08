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
#include <stdio.h>
#include <unistd.h>
#include <sys/stat.h>
#include <pthread.h>
#include <signal.h>

#import "FLVRVideo.h"
#import "FLVRVideo+Private.h"
#import "FLVRVideoInterceptor.h"
#import "FLVRVideoInterceptor+Private.h"

extern int MDItemSetAttribute(MDItemRef item, CFStringRef attribute, CFTypeRef value);

NSString* FLVRVideoRegisteredNotification = \
    @"FLVRVideoRegisteredNotification";
NSString* FLVRVideoUnregisteredNotification = \
    @"FLVRVideoUnregisteredNotification";
NSString* FLVRVideoProgressNotification = \
    @"FLVRVideoProgressNotification";
NSString* FLVRVideoEncodingNotification = \
    @"FLVRVideoEncodingNotification";
NSString* FLVRVideoCompleteNotification = \
    @"FLVRVideoCompleteNotification";
    
static NSMutableArray* allRegisteredVideos;
static NSLock* lock;

static void pipeWrench(int signo) 
{
//    printf("Caught SIGPIPE.");
}


@implementation FLVRVideo

static NSArray* extensionsToStrip;

+ (void) initialize
{
    if (self == [FLVRVideo class]) {
        lock = [[NSLock alloc] init];
        allRegisteredVideos = [[NSMutableArray alloc] initWithCapacity:10];
        extensionsToStrip = [[NSArray alloc] initWithObjects:@".txt", @".flv", nil];
    }
}

+ (NSArray*) registeredVideos
{
    [lock lock];
    NSArray* copy = [allRegisteredVideos copy];
    [lock unlock];
    return [copy autorelease];
}

+ (void) registerVideo:(FLVRVideo*)video
{
    [video retain];
    [lock lock];
    [allRegisteredVideos insertObject:video atIndex:0];
    [lock unlock];
    [[NSNotificationCenter defaultCenter] performSelectorOnMainThread:@selector(postNotification:) withObject:[NSNotification notificationWithName:FLVRVideoRegisteredNotification object:video] waitUntilDone:NO];
    [video autorelease];
}

+ (void) unregisterVideo:(FLVRVideo*)video
{
    [video retain];
    [lock lock];
    [allRegisteredVideos removeObject:video];
    [lock unlock];
    [[NSNotificationCenter defaultCenter] performSelectorOnMainThread:@selector(postNotification:) withObject:[NSNotification notificationWithName:FLVRVideoUnregisteredNotification object:video] waitUntilDone:NO];
    [video autorelease];
}

//  ------------------------------------------------------------------------

- (id) initWithType:(NSString*)_type response:(NSHTTPURLResponse*)_response interceptor:(FLVRVideoInterceptor*)_interceptor;
{
    if (self = [super init]) {
        state = FLVRVideoCheck;
        type = [_type retain];
        response = [_response retain];
        interceptor = _interceptor;
        info = [[NSMutableDictionary dictionaryWithCapacity:10] retain];
        fileHandleForReading = fileHandleForWriting = fileHandleForWritingToCodec = -1;
        firstFrameBuffer = [[NSMutableData alloc] initWithCapacity:(1024 * 128)];

        expectedContentLength = [response expectedContentLength];
        if (expectedContentLength == -1) {
            NSLog(@"No Content Length!");
        }

        /*  Create a temporary file to buffer the FLV data, in case the user 
         *  wants to process it.  We open a read and write handle to the same
         *  file and then unlink it.  This makes sure that when Safari exits, 
         *  all of our temporary crap is cleaned up.
         */
        char* name = tmpnam(NULL);
        fileHandleForWriting = open(name, O_WRONLY | O_CREAT | O_TRUNC, 0600);
        fileHandleForReading = open(name, O_RDONLY);
        unlink(name);
        if (fileHandleForWriting == -1 || fileHandleForReading == -1) {
            return nil;
        }
        if (-1 == (fileHandleForWritingToCodec = [self _launchCodecTask])) {
            return nil;
        }

        state = FLVRVideoDownloading;
    }
    return self;
}

- (void) dealloc
{
    NSAssert(pidForCodec == 0, @"");
    NSAssert(pidForSed == 0, @"");

    if (fileHandleForReading > -1) {
        close(fileHandleForReading);
    }
    if (fileHandleForWriting > -1) {
        close(fileHandleForWriting);
    }
    if (fileHandleForWritingToCodec > -1) {
        close(fileHandleForWritingToCodec);
    }

    [type release];
    [connection release];
    [response release];
    [firstFrame release];
    [filename release];
    [info release];
    [fullPathToEncodedFile release];
    [fullPathToTempFile release];
    [firstFrameBuffer release];

    [super dealloc];
}

- (NSString*) filename
{
    if (!filename) {
        filename = [[response suggestedFilename] lastPathComponent];

        if (NSNotFound != [filename rangeOfString:@"rom www.metacafe.com] "].location) {
            filename = [NSString stringWithFormat:@"MetaCafe Video #%@", [filename substringFromIndex:24]]; 
        } else if ([filename isEqualTo:@"get_video"]) {
            NSString* absoluteString = [[response URL] absoluteString];
            int index;
            if (NSNotFound != (index = [absoluteString rangeOfString:@"video_id="].location)) {
                filename = [NSString stringWithFormat:@"YouTube Video #%@", [absoluteString substringFromIndex:(index + 9)]]; 
            } else {
                filename = @"Untitled Video";
            }
        }

        for (int i = 0, imax = [extensionsToStrip count]; i < imax; i++) {
            if ([filename hasSuffix:[extensionsToStrip objectAtIndex:i]]) {
                filename = [filename stringByDeletingPathExtension];
                i = 0;
                continue;
            }
        }

        [filename retain];
    }
    return filename;
}

- (void) setFilename:(NSString*)_filename
{
    if (filename != _filename) {
        [filename release];
        filename = [_filename retain];
    }
}

- (int) state
{
    return state;
}

- (float) percentDownloaded
{
    return percentDownloaded;
}

- (float) percentEncoded
{
    return percentEncoded;
}

- (BOOL) shouldAllowCancel
{
    return !willEncode;
}

- (NSImage*) firstFrame
{
    return [[firstFrame retain] autorelease];
}

- (NSDictionary*) info
{
    return [[info retain] autorelease];
}

- (NSString*) fullPathToEncodedFile
{
    return [[fullPathToEncodedFile retain] autorelease];
}

- (void) beginEncoding
{
    if (state == FLVRVideoDownloading) {
        if (1.0 == percentDownloaded) {
            [self _launchEncodingTask];
        } else {
            willEncode = YES;
        }
    }
}

- (void) cancel
{
    [interceptor _detachVideo];
    interceptor = nil;
    [connection release];
    connection = nil;
    [FLVRVideo unregisterVideo:self];
    [self _killTasks];
}

@end

@implementation FLVRVideo (Private)

- (void) _killTasks
{
    if (pidForCodec) {
        kill(pidForCodec, 9);
    }
    if (pidForSed) {
        kill(pidForSed, 9);
    }
}

- (void) _complete
{
    [interceptor _detachVideo];
    interceptor = nil;
    [connection release];
    connection = nil;
    percentDownloaded = 1.0;
    if (fileHandleForWriting > -1) {
        close(fileHandleForWriting);
        fileHandleForWriting = -1;
    }
    [[NSNotificationCenter defaultCenter] performSelectorOnMainThread:@selector(postNotification:) withObject:[NSNotification notificationWithName:FLVRVideoProgressNotification object:self] waitUntilDone:NO];
    if (willEncode) {
        [self _launchEncodingTask];
    }
}

- (void) _takeOwnershipOfConnection:(NSURLConnection*)_connection
{
    connection = [_connection retain];
}

- (void) _processData:(NSData*)data
{
    if (fileHandleForWritingToCodec > -1 && firstFrameBuffer) {
        [firstFrameBuffer appendData:data];
        if ([firstFrameBuffer length] > (1024 * 192)) {
            sig_t oldPipeHandler = signal(SIGPIPE, pipeWrench);
            @try {
                if (-1 == write(fileHandleForWritingToCodec, [firstFrameBuffer bytes], [firstFrameBuffer length])) {
                    close(fileHandleForWritingToCodec);
                    fileHandleForWritingToCodec = -1;
                    [firstFrameBuffer release];
                    firstFrameBuffer = nil;
                }
            } @finally {
                signal(SIGPIPE, oldPipeHandler);
            }
        }
    }
    write(fileHandleForWriting, [data bytes], [data length]);
    if (expectedContentLength > 0) {
        float percent = (float)((double)lseek(fileHandleForWriting, 0, SEEK_CUR) / (double)expectedContentLength);
        if (floor(percent * 100) > floor(percentDownloaded * 100)) {
            [[NSNotificationCenter defaultCenter] performSelectorOnMainThread:@selector(postNotification:) withObject:[NSNotification notificationWithName:FLVRVideoProgressNotification object:self] waitUntilDone:NO];
        }
        percentDownloaded = percent;
    }
}

- (void) _launchEncodingTask
{
    state = FLVRVideoEncoding;
    [[NSNotificationCenter defaultCenter] performSelectorOnMainThread:@selector(postNotification:) withObject:[NSNotification notificationWithName:FLVRVideoEncodingNotification object:self] waitUntilDone:NO];

    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults synchronize];
	NSDictionary* options = [userDefaults persistentDomainForName:@"com.tastyapps.flvr"];
	NSFileManager* fileManager = [NSFileManager defaultManager];
	
	/*  Check that the format is one we support.
	 */
	NSString* format = [[options objectForKey:@"flvr.format"] lowercaseString];
    if ([@".avi" isEqualTo:format]) {
    } else if ([@".flv" isEqualTo:format]) {
	} else if ([@".mov" isEqualTo:format]) {
	} else if ([@".mp4" isEqualTo:format]) {
	} else {
		NSLog(@"Unsupported format: %@", format); 
		return;
	}

	/*  Audio Codec
	 */
	NSString* audioCodec = [[options objectForKey:@"flvr.audioCodec"] lowercaseString];
	if ([@"aac" isEqualTo:audioCodec]) {
	} else if ([@"mp3" isEqualTo:audioCodec]) {
	} else {
		NSLog(@"Unsupported audio codec: %@", audioCodec); 
		return;
	}

	/*  Video Bitrate
	 */
	int audioBitrate = [[options objectForKey:@"flvr.audioBitrate"] intValue];
	if (audioBitrate > 300 || audioBitrate < 10) {
		NSLog(@"Unsupported audio bit-rate: %d", audioBitrate); 
		return;
	}

	/*  Video Codec
	 */
	NSString* videoCodec = [[options objectForKey:@"flvr.videoCodec"] lowercaseString];
	if ([@"mpeg4" isEqualTo:videoCodec]) {
	} else if ([@"h264" isEqualTo:videoCodec]) {
	} else if ([@"copy" isEqualTo:videoCodec]) {
	} else {
		NSLog(@"Unsupported video codec: %@", videoCodec); 
		return;
	}

	/*  Video Bitrate
	 */
	int videoBitrate = [[options objectForKey:@"flvr.videoBitrate"] intValue];
	if (videoBitrate > 2000 || videoBitrate < 150) {
		NSLog(@"Unsupported video bit-rate: %d", videoBitrate); 
		return;
	}

	int videoMaxrate = [[options objectForKey:@"flvr.videoMaxrate"] intValue];
	if (videoMaxrate > 2000 || videoMaxrate < 150 || videoMaxrate < videoBitrate) {
		NSLog(@"Unsupported video max-rate: %d", videoMaxrate); 
		return;
	}

	int videoBufsize = [[options objectForKey:@"flvr.videoBufsize"] intValue];
	if (videoBufsize > 10240 || videoBufsize < 150) {
		NSLog(@"Unsupported video buffer size: %d", videoBufsize); 
		return;
	}
    
    BOOL deinterlace = [[options objectForKey:@"flvr.deinterlace"] intValue];

	int audioQuality = 250;
	
	/*  Create the destination folder, if it doesn't exist.  Build
	 *  the file names.
	 */
	NSString* rawDestinationFolder = [options objectForKey:@"flvr.destinationFolder"];
	NSString* destinationFolder = [rawDestinationFolder stringByExpandingTildeInPath]; 
	if (!destinationFolder) {
		NSLog(@"Unsupported destination folder: %@", rawDestinationFolder); 
	}
	[fileManager createDirectoryAtPath:destinationFolder attributes:nil];
    NSString* outputFileName = [NSString stringWithFormat:@"%@%@", [self filename], format];
    fullPathToEncodedFile = [[destinationFolder stringByAppendingPathComponent:outputFileName] retain];
    fullPathToTempFile = [[destinationFolder stringByAppendingPathComponent:[NSString stringWithFormat:@".%@", outputFileName]] retain];

    /*  Build the command to invoke the encoder.
     */
    NSMutableArray* arguments;
    NSString* launchPath = nil;
    if ([@".flv" isEqualTo:format]) {
        launchPath = @"/bin/dd";
        arguments = [NSArray arrayWithObjects: 
            @"bs=256k",
            [NSString stringWithFormat:@"of=%@", fullPathToTempFile],
            nil
        ];
    } else {
        launchPath = [[NSBundle bundleForClass:[self class]] pathForResource:@"ffmpeg" ofType:@""];
		arguments = [NSMutableArray arrayWithArray:[[NSString stringWithFormat:@"-f %@ -i -", type] componentsSeparatedByString:@" "]];
        if (deinterlace) {
            [arguments addObject:@"-deinterlace"];
        }
		[arguments addObjectsFromArray:[[NSString stringWithFormat:@"-vcodec %@", videoCodec] componentsSeparatedByString:@" "]]; 
		if (![@"copy" isEqualTo:videoCodec]) {
			[arguments addObjectsFromArray:[[NSString stringWithFormat:@"-b %dk -maxrate %dk -bufsize %dk", videoBitrate, videoMaxrate, videoBufsize] componentsSeparatedByString:@" "]]; 
		}
		[arguments addObjectsFromArray:[[NSString stringWithFormat:@"-acodec %@", audioCodec] componentsSeparatedByString:@" "]]; 
		if (![@"copy" isEqualTo:audioCodec]) {
			[arguments addObjectsFromArray:[[NSString stringWithFormat:@"-g %d -ab %dk", audioQuality, audioBitrate] componentsSeparatedByString:@" "]];
		}
		[arguments addObject:@"-y"];
        if ([@".mov" isEqualTo:format]) {
            [arguments addObject:@"-f"];
            [arguments addObject:@"mov"];
        } else if ([@".mp4" isEqualTo:format]) {
            [arguments addObject:@"-f"];
            [arguments addObject:@"mp4"];
        }
        [arguments addObject:fullPathToTempFile];
    }
    
    /*  Build the list of arguments as a C-array, to feed to execv()
     */
    const char* execArguments[0x20];
    const char* codec = [launchPath fileSystemRepresentation];
    execArguments[0] = [[launchPath lastPathComponent] fileSystemRepresentation];
    for (int i = 1, imax = [arguments count] + 1; i < imax; i++) {
        execArguments[i] = (char*)[[arguments objectAtIndex:i-1] fileSystemRepresentation];
    }
    execArguments[[arguments count]+1] = NULL;

#ifdef DEBUG
	NSLog(@"%s %@", execArguments[0], [arguments componentsJoinedByString:@" "]);
#endif	

    /*  Fork and start the codec process...  but lower the priority of it using
     *  nice() before we do.
     */
    int pe[2]; pe[0] = pe[1] = 0; pipe(pe);
    if (0 == (pidForCodec = vfork())) {
        close(pe[0]);
        dup2(fileHandleForReading, 0);
        dup2(pe[1], 2);
        nice(20);
        execv(codec, (void*)execArguments);
        perror("export: ");
        exit(-1);
    } else {
        close(fileHandleForReading);
        close(pe[1]);
    }
    [NSThread detachNewThreadSelector:@selector(_readExportOutput:) toTarget:self withObject:[NSDictionary dictionaryWithObjectsAndKeys:
        [NSNumber numberWithInt:pe[0]],
        @"fileDescriptor",
        nil
    ]];
}

- (void) _readExportOutput:(NSDictionary*)data
{
    int fileDescriptor = [[data objectForKey:@"fileDescriptor"] intValue];
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    sig_t oldPipeHandler = signal(SIGPIPE, pipeWrench);
    @try {
        float duration = 0;
        if ([info objectForKey:@"duration"]) {
            duration = [[info objectForKey:@"duration"] floatValue];
        }
        
        /*  Read until the end of the stream.  
         */
        NSMutableData* data = [NSMutableData data];
        char b;
        while (0 < read(fileDescriptor, &b, 1)) {
            if (b == '\r' || b == '\n') {
                NSString* line = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
                if (duration > 0 && [line hasPrefix:@"frame="]) {
                    int index = [line rangeOfString:@"time="].location;
                    if (index != NSNotFound) {
                        line = [line substringFromIndex:index + 5];
                        index = [line rangeOfString:@" "].location;
                        if (index != NSNotFound) {
                            percentEncoded = [[line substringToIndex:index] floatValue] / duration;
                            [[NSNotificationCenter defaultCenter] performSelectorOnMainThread:@selector(postNotification:) withObject:[NSNotification notificationWithName:FLVRVideoProgressNotification object:self] waitUntilDone:NO];
                        }
                    }
                }
                [data setLength:0];
            } else {
                [data appendBytes:&b length:1];
            }
        }

        /*  Close out the process by reading it's exit status.
         */
        int status = 0;
        waitpid(pidForCodec, &status, 0);
        pidForCodec = 0;
        if (status == 0) {
            /*  Send a notification
             */
            percentEncoded = 1.0;
            [[NSNotificationCenter defaultCenter] performSelectorOnMainThread:@selector(postNotification:) withObject:[NSNotification notificationWithName:FLVRVideoProgressNotification object:self] waitUntilDone:NO];

            /*  Move the output into place.
             */
            unlink([fullPathToEncodedFile fileSystemRepresentation]);
            rename(
                [fullPathToTempFile fileSystemRepresentation], 
                [fullPathToEncodedFile fileSystemRepresentation]
            );

            /*  Tag the output file.
             */
            MDItemRef item = MDItemCreate(NULL, (CFStringRef)fullPathToEncodedFile);
            if (item) {
                MDItemSetAttribute(
                    item, 
                    kMDItemEncodingApplications,
                    [NSArray arrayWithObjects:@"TastyApps FLVR", nil]
                );
                CFRelease(item);
            }

            state = FLVRVideoFinished;
            [[NSNotificationCenter defaultCenter] performSelectorOnMainThread:@selector(postNotification:) withObject:[NSNotification notificationWithName:FLVRVideoCompleteNotification object:self] waitUntilDone:NO];
        }
    } @catch (NSException* e) {
        unlink([fullPathToTempFile fileSystemRepresentation]);
    } @finally {
        signal(SIGPIPE, oldPipeHandler);
        [pool release];
    }
}

- (int) _launchCodecTask
{
    int stdinForCodec = -1;
    int stderrForCodec = -1;
    {
        char* ffmpeg = (char*)[[[NSBundle bundleForClass:[self class]] pathForResource:@"ffmpeg" ofType:@""] fileSystemRepresentation];
        int pi[2]; pi[0] = pi[1] = 0; pipe(pi);
        int po[2]; po[0] = po[1] = 0; pipe(po);
        int pe[2]; pe[0] = pe[1] = 0; pipe(pe);

        NSArray* arguments = [[NSString stringWithFormat:@"-f %@ -i - -ss 1.0 -vframes 1 -f image2pipe -vcodec bmp -", type] componentsSeparatedByString:@" "];
        char* execArguments[0x20];
        execArguments[0] = ffmpeg;
        for (int i = 1, imax = [arguments count] + 1; i < imax; i++) {
            execArguments[i] = (char*)[[arguments objectAtIndex:i-1] fileSystemRepresentation];
        }
        execArguments[[arguments count]+1] = NULL;
#ifdef DEBUG
        NSLog(@"%@", [arguments componentsJoinedByString:@" "]);
#endif

        if (0 == (pidForCodec = vfork())) {
            close(pi[1]);
            close(po[0]);
            close(pe[0]);
            dup2(pi[0], 0);
            dup2(po[1], 1);
            dup2(pe[1], 2);
            execv(ffmpeg, execArguments);
            perror("beginFirstFrame: ffmpeg: ");
            exit(-1);
        } else {
            close(pi[0]);
            close(po[1]);
            close(pe[1]);
            stdinForCodec = pi[1];
            stderrForCodec = pe[0];
        }
        [NSThread detachNewThreadSelector:@selector(_readFirstFrameOutput:) toTarget:self withObject:[NSDictionary dictionaryWithObjectsAndKeys:
            [NSNumber numberWithInt:po[0]],
            @"fileDescriptor",
            [NSNumber numberWithInt:pidForCodec],
            @"pidForCodec",
            nil
        ]];
    }

    {
        char* sed = "/usr/bin/sed";
        int po[2]; po[0] = po[1] = 0; pipe(po);
        if (0 == (pidForSed = vfork())) {
            close(po[0]);
            dup2(stderrForCodec, 0);
            dup2(po[1], 1);
            char* const parameters[] = {
                sed, "-n", "/^  Duration/,/^Output/!d;s/[ ]  */ /g;s/^ //p", NULL
            };
            execv(sed, parameters);
            perror("beginFirstFrame: sed: ");
            exit(-1);
        } else {
            close(stderrForCodec);
            close(po[1]);
        }
        [NSThread detachNewThreadSelector:@selector(_readInfoOutput:) toTarget:self withObject:[NSDictionary dictionaryWithObjectsAndKeys:
            [NSNumber numberWithInt:po[0]],
            @"fileDescriptor",
            [NSNumber numberWithInt:pidForSed],
            @"pidForSed",
            nil
        ]];
    }

    return stdinForCodec;
}

- (void) _readFirstFrameOutput:(NSDictionary*)data
{
    int fileDescriptor = [[data objectForKey:@"fileDescriptor"] intValue];
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    sig_t oldPipeHandler = signal(SIGPIPE, pipeWrench);
    @try {
        /*  Read until the end of the stream.  
         */
        NSMutableData* data = [NSMutableData dataWithCapacity:0x8000];
        char buffer[0x800];
        int bytesRead;
        while (0 < (bytesRead = read(fileDescriptor, buffer, sizeof(buffer)))) {
            [data appendBytes:buffer length:bytesRead];
        }
        int status = 0;
        waitpid(pidForCodec, &status, 0);
        pidForCodec = 0;

        /*  Process the data into an image.  Notify if successful.
         */
        if (firstFrame = [[NSImage alloc] initWithData:data]) {
            /*  Post a notification telling whoever is listening that a new FLV
             *  is available for the snagging.
             */ 
            [FLVRVideo registerVideo:self];
        }
    } @finally {
        close(fileDescriptor);
        signal(SIGPIPE, oldPipeHandler);
        [pool release];
    }
}

- (void) _readInfoOutput:(NSDictionary*)data
{
    int fileDescriptor = [[data objectForKey:@"fileDescriptor"] intValue];
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    sig_t oldPipeHandler = signal(SIGPIPE, pipeWrench);
    @try {
        /*  Read until the end of the stream.  
         */
        NSMutableData* data = [NSMutableData dataWithCapacity:0x8000];
        char buffer[0x800];
        int bytesRead;
        while (0 < (bytesRead = read(fileDescriptor, buffer, sizeof(buffer)))) {
            [data appendBytes:buffer length:bytesRead];
        }
        int status = 0;
        waitpid(pidForSed, &status, 0);
        pidForSed = 0;
         
        BOOL audioInfo = NO;
        BOOL videoInfo = NO;
        NSArray* lines = [[[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease] componentsSeparatedByString:@"\n"];
#ifdef DEBUG
        NSLog(@"%@", lines);
#endif
        for (int i = 0, imax = [lines count]; i < imax; i++) {
            @try {
                NSArray* fields = [[lines objectAtIndex:i] componentsSeparatedByString:@" "];
                NSString* t = [fields objectAtIndex:0];
                if ([@"Duration:" isEqualTo:t]) {
                    NSString* duration = [[fields objectAtIndex:1] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@","]];
                    if (![@"N/A" isEqualTo:duration]) {
                        [info setObject:[NSNumber numberWithFloat:[[duration substringFromIndex:6] floatValue] + (60 * [[duration substringWithRange:NSMakeRange(3,5)] intValue]) + (60 * 60 * [[duration substringWithRange:NSMakeRange(0,2)] intValue])] forKey:@"duration"];
                    }
                } else if ([@"Stream" isEqualTo:t]) {
                    t = [fields objectAtIndex:2];
                    if ([@"Video:" isEqualTo:t] && !videoInfo) {
                        [info setObject:[[[fields objectAtIndex:3] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@","]] uppercaseString] forKey:@"videoCodec"];
                        [info setObject:[NSNumber numberWithFloat:[[fields objectAtIndex:6] floatValue]] forKey:@"videoFrameRate"];
                        videoInfo = YES;
                    } else if ([@"Audio:" isEqualTo:t] && !audioInfo) {
                        [info setObject:[[[fields objectAtIndex:3] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@","]] uppercaseString] forKey:@"audioCodec"];
                        [info setObject:[NSNumber numberWithInt:[[fields objectAtIndex:4] intValue]] forKey:@"audioSamplingRate"];
                        [info setObject:[NSNumber numberWithInt:([@"mono" isEqualTo:[fields objectAtIndex:6]] ? 1 : 2)] forKey:@"audioChannels"];
                        audioInfo = YES;
                    }
                }
            }
            @catch (NSException *exception) {
                NSLog(@"_infoAvailable: Caught %@: %@", [exception name], [exception  reason]);
            }
        }
#ifdef DEBUG
        NSLog(@"%@", info);
#endif
    } @finally {
        close(fileDescriptor);
        signal(SIGPIPE, oldPipeHandler);
        [pool release];
    }
}

@end