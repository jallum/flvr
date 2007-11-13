#import "NSBezierPath+TastyApps.h"
#import "FLVR.h"
#import "FLVRVideo.h"
#import "FLVRNowPlayingView.h"
#import <objc/objc-class.h>
#import <WebKit/WebKit.h>

static BOOL swapInstanceImplementations(Class aClass, SEL selA, SEL selB)
{
    Method methodA = class_getInstanceMethod(aClass, selA);
    Method methodB = class_getInstanceMethod(aClass, selB);
    if (methodA != nil && methodB != nil) {
        IMP i = methodA->method_imp;
        methodA->method_imp = methodB->method_imp;
        methodB->method_imp = i;
        return YES;
    } else {
        return NO;
    }
}

@interface TossToController (Private)
- (void) _registeredVideo:(NSNotification*)notification;
- (void) _unregisteredVideo:(NSNotification*)notification;
- (void) _progress:(NSNotification*)notification;
- (void) _complete:(NSNotification*)notification;
@end

@implementation TossToController

+ (void) initialize
{
	if (self == [TossToController class]) {
        swapInstanceImplementations(
            [NSURLConnection class], 
            @selector(initWithRequest:delegate:), 
            @selector(FLVR_initWithRequest:delegate:)
        );
        swapInstanceImplementations(
            [NSURLConnection class], 
            @selector(cancel), 
            @selector(FLVR_cancel)
        );
	}
}

- (id) init
{
    if (self = [super init]) {
        _downloadImmediately = YES;
    }
    return self;
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}


//	-------------------------------------------------------------------------
#pragma mark                 -- Notifications --
//	-------------------------------------------------------------------------

- (void) _urlsDropped:(NSNotification*)notification 
{
    NSString* url = [[[notification userInfo] objectForKey:@"url"] retain];
    
    WebFrame* frame = [_webView mainFrame];
    [frame stopLoading];
    [frame loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:url]]];
}


//	-------------------------------------------------------------------------
#pragma mark                    -- Unsorted --
//	-------------------------------------------------------------------------

- (void) awakeFromNib
{
	/*  Read the defaults file into memory, and register them with the 
	 *  UserDefaults manager.
	 */
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    NSDictionary* defaults = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"defaults" ofType:@"plist"]];
    [userDefaults addSuiteNamed:@"com.tastyapps.flvr"];    
    [userDefaults registerDefaults:defaults];
    NSDictionary* existing = [userDefaults persistentDomainForName:@"com.tastyapps.flvr"];
    if (existing) {
        NSMutableDictionary* combined = [defaults mutableCopy];
        [combined addEntriesFromDictionary:existing];
        [userDefaults setPersistentDomain:combined forName:@"com.tastyapps.flvr"];
        [combined release];
    } else {
        [userDefaults setPersistentDomain:defaults forName:@"com.tastyapps.flvr"];
    }
    [userDefaults synchronize];

	NSNotificationCenter* defaultCenter = [NSNotificationCenter defaultCenter];
    [defaultCenter addObserver:self selector:@selector(_registeredVideo:) name:FLVRVideoRegisteredNotification object:nil];
    [defaultCenter addObserver:self selector:@selector(_unregisteredVideo:) name:FLVRVideoUnregisteredNotification object:nil];
    [defaultCenter addObserver:self selector:@selector(_progress:) name:FLVRVideoProgressNotification object:nil];
    [defaultCenter addObserver:self selector:@selector(_progress:) name:FLVRVideoEncodingNotification object:nil];
    [defaultCenter addObserver:self selector:@selector(_complete:) name:FLVRVideoCompleteNotification object:nil];
	[defaultCenter addObserver:self selector:@selector(_urlsDropped:) name:@"UrlDropped" object:nil];
    [defaultCenter addObserver:self selector:@selector(_webViewProgressStartedNotification:) name:WebViewProgressStartedNotification object:nil];
    [defaultCenter addObserver:self selector:@selector(videoCompleted:) name:FLVRVideoCompleteNotification object:nil];
  }

- (void) revealInFinder:(FLVRVideo*)video
{    
    [[NSWorkspace sharedWorkspace] selectFile:[video fullPathToEncodedFile] inFileViewerRootedAtPath:@""];
}

- (void) addToiTunes:(FLVRVideo*)video
{
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    CFURLRef url = CFURLCreateWithFileSystemPath(NULL, (CFStringRef)[video fullPathToEncodedFile], kCFURLPOSIXPathStyle, NO);
    CFStringRef path = CFURLCopyFileSystemPath(url, kCFURLHFSPathStyle);
    NSString* script = [NSString stringWithFormat:
        @"ignoring application responses\n"
        @"    tell application \"iTunes\" to add (\"%@\" as alias) to library playlist 1\n"
        @"end ignoring\n",
        path
    ];
    CFRelease(path);
    CFRelease(url);
    NSDictionary* error = nil;
    @try {
//        NSLog(@"%@", script);
        [[[[NSAppleScript alloc] initWithSource:script] autorelease] executeAndReturnError:&error];
    } @catch (NSException* e) {
        NSLog(@"result: %@", e);
    }
    NSLog(@"result: %@", error);
    [pool release];
}

- (void) sendToGrowl:(FLVRVideo*)video
{
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    NSDictionary* error = nil;
    NSAppleEventDescriptor* value = nil;

    @try {
        NSString* checkScript = [NSString stringWithFormat:
            @"tell application \"System Events\" to return count of (every process whose name is \"GrowlHelperApp\") > 0\n"
        ];
        NSLog(@"%@", checkScript);
        value = [[[[NSAppleScript alloc] initWithSource:checkScript] autorelease] executeAndReturnError:&error];
        if (!error && value && [value booleanValue]) {
            NSMutableString* name = [[[video filename] mutableCopy] autorelease]; 
            [name replaceOccurrencesOfString:@"\\" withString:@"\\\\" options:NSAnchoredSearch range:NSMakeRange(0, [name length])];
            [name replaceOccurrencesOfString:@"\"" withString:@"\\\"" options:NSAnchoredSearch range:NSMakeRange(0, [name length])];
            NSString* script = [NSString stringWithFormat:
                @"ignoring application responses\n"
                @"    tell application \"GrowlHelperApp\"\n"
                @"        set notification to \"Video Download Complete\"\n"
                @"        register as application \"FLVR\" all notifications {notification} default notifications {notification}\n"
                @"        notify with name notification title \"%@\" description \"%@\" application name \"FLVR\" image from location \"%@\"\n"
                @"    end tell\n"
                @"end ignoring\n",
                FLVRLocalizedString(@"Video Download Complete", @""),
                name,
                [NSURL fileURLWithPath:[[NSBundle bundleForClass:[self class]] pathForResource:@"FLVR" ofType:@"icns"]]
            ];
            @try {
//                NSLog(@"%@", script);
                [[[[NSAppleScript alloc] initWithSource:script] autorelease] executeAndReturnError:&error];
            } @catch (NSException* e) {
                NSLog(@"exception: %@", e);
            }
            NSLog(@"result: %@", error);
        }
    } @catch (NSException* e) {
        NSLog(@"exception: %@", e);
    }
    [pool release];
}

- (void) videoCompleted:(NSNotification*)notification
{
    FLVRVideo* video = [notification object];

    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults synchronize];
    NSDictionary* options = [userDefaults persistentDomainForName:@"com.tastyapps.flvr"];

    @try {
        id value = [options objectForKey:@"flvr.addToiTunes"];
        if (value && [value boolValue]) {
            [self performSelector:@selector(addToiTunes:) withObject:video afterDelay:0.1];
        }
    } @catch (NSException* e) {
        NSLog(@"videoCompleted: %@", e);
    }

    @try {
        id value = [options objectForKey:@"flvr.sendToGrowl"];
        if (value && [value boolValue]) {
            [self performSelector:@selector(sendToGrowl:) withObject:video afterDelay:0.1];
        }
    } @catch (NSException* e) {
        NSLog(@"videoCompleted: %@", e);
    }
}

@end

@implementation TossToController (Private)

- (void) _cancel:(id)sender
{
    NSLog(@"cancel");
    [_dropTargetView setHidden:NO];
    [_waitASecView setHidden:YES];
    [_progressIndicator stopAnimation:nil];
    [_webView stopLoading:nil];
}

- (void) _registeredVideo:(NSNotification*)notification
{
    [_nowPlayingView addVideo:[notification object]];

    [_dropTargetView setHidden:NO];
    [_waitASecView setHidden:YES];
    [_progressIndicator stopAnimation:nil];
    if (_videoTimer) {
        [_videoTimer invalidate];
        [_videoTimer release];
        _videoTimer = nil;
    }
}

- (void) _unregisteredVideo:(NSNotification*)notification
{
    [_nowPlayingView removeVideo:[notification object]];
}

- (void) _progress:(NSNotification*)notification
{
    [_nowPlayingView updateCellForVideo:[notification object]];
}

- (void) _complete:(NSNotification*)notification
{
    [_nowPlayingView updateCellForVideo:[notification object]];
}

- (void) _webViewProgressStartedNotification:(NSNotification*)notification
{
    [_dropTargetView setHidden:YES];
    [_waitASecView setHidden:NO];
    [_progressIndicator startAnimation:nil];
    _videoTimer = [[NSTimer timerWithTimeInterval:30.0 target:self selector:@selector(_cancel:) userInfo:nil repeats:NO] retain];
}

@end