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
}

@end

@implementation TossToController (Private)

- (void) _registeredVideo:(NSNotification*)notification
{
    [_nowPlayingView addVideo:[notification object]];
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

@end