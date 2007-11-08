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

#import "FLVR.h"
#import <openssl/rsa.h>
#import <openssl/sha.h>
#import <objc/objc-class.h>
#import <Carbon/Carbon.h>
#import "ToolbarController+FLVR.h"
#import "FLVRNowPlayingWindowController.h"
#import "FLVROptionsWindowController.h"
#import "FLVRVideo.h"

static BOOL supplyInstanceImplementationIfNotPresent(Class aClass, SEL selA, SEL selB)
{
    Method methodA = class_getInstanceMethod(aClass, selA);
    Method methodB = class_getInstanceMethod(aClass, selB);
    if (methodA == nil && methodB != nil) {
        struct objc_method_list* ml = calloc(1, sizeof(struct objc_method_list));
        ml->method_count = 1;
        ml->method_list[0].method_name  = sel_registerName((char*)selA);
        ml->method_list[0].method_types = methodB->method_types;
        ml->method_list[0].method_imp   = methodB->method_imp;
        class_addMethods(aClass, ml);
        return YES;
    } else {
        return NO;
    }
}

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

@implementation FLVR

static FLVR* sharedInstance;

+ (FLVR*) sharedInstance
{
    if (nil == sharedInstance) {
        sharedInstance = [[FLVR alloc] init];
    }
    return sharedInstance;
}

+ (void) install
{
    if ([@"com.apple.Safari" isEqualTo:[[NSBundle mainBundle] bundleIdentifier]]) {
        /*  Add in default implementations, if they don't already exist.
         */
        supplyInstanceImplementationIfNotPresent(
            [BrowserWindowController class],
            @selector(window:willPositionSheet:usingRect:),
            @selector(FLVR_notPresent_window:willPositionSheet:usingRect:)
        );

        /*  Hijack the implementations of a few key methods. 
         */
        swapInstanceImplementations(
            [BrowserWindowController class],
            @selector(window:willPositionSheet:usingRect:),
            @selector(FLVR_window:willPositionSheet:usingRect:)
        );

        swapInstanceImplementations(
            [BrowserDocument class],
            @selector(validateUserInterfaceItem:),
            @selector(FLVR_validateUserInterfaceItem:)
        );
        
        swapInstanceImplementations(
            [ToolbarController class], 
            @selector(toolbar:itemForItemIdentifier:willBeInsertedIntoToolbar:),
            @selector(FLVR_toolbar:itemForItemIdentifier:willBeInsertedIntoToolbar:)
        );
        swapInstanceImplementations(
            [ToolbarController class], 
            @selector(toolbarAllowedItemIdentifiers:), 
            @selector(FLVR_toolbarAllowedItemIdentifiers:)
        );
    }

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

    /*  Finish up.
     */
    [[FLVR sharedInstance] performSelectorOnMainThread:@selector(completeInstallation) withObject:nil waitUntilDone:NO];
}

- (void) completeInstallation
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

    /*  Register a notification listener for video completion.
     */
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(videoCompleted:) name:FLVRVideoCompleteNotification object:nil];
    
    /*  Hijack a spot on Safari's application menu.
    */
    NSMenu* mainMenu = [[NSApplication sharedApplication] mainMenu];
    if (mainMenu) {
        NSMenu* viewMenu = [[mainMenu itemAtIndex:3] submenu];
        if (viewMenu) {
            /**/
            NSMenuItem* menuItem = [[NSMenuItem alloc] initWithTitle:FLVRLocalizedString(@"Show FLVR...", @"") action:@selector(showNowPlaying:) keyEquivalent:@"n"];
            [menuItem setTarget:[FLVR sharedInstance]];
            [menuItem setKeyEquivalentModifierMask:NSAlternateKeyMask | NSCommandKeyMask];
            [viewMenu insertItem:menuItem atIndex:12];
        }
    }

    /*  For anyone watching (that cares)...
     */
    NSLog(@"FLVR Installed.");
}

- (id) init
{
    if (self = [super init]) {
    }
    return self;
}

- (void) dealloc
{
    [super dealloc];
}

- (BOOL) validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)item
{
    if ([item action] == @selector(showNowPlaying:)) {
        return [[NSApp keyWindow] isKindOfClass:[BrowserWindow class]];
    } else {
        return NO;
    }
}

- (void) showNowPlaying:(id)sender
{
    [self showNowPlayingForWindow:[NSApp keyWindow]];
}

- (void) showNowPlayingForWindow:(NSWindow*)window
{
    if (GetCurrentKeyModifiers() & (1 << optionKeyBit)) {
        FLVROptionsWindowController* controller = [[FLVROptionsWindowController alloc] initWithWindowNibName:@"Options"];
        [NSApp beginSheet:[controller window] modalForWindow:window modalDelegate:self didEndSelector:@selector(_optionsSheetDidEnd:returnCode:contextInfo:) contextInfo:controller];
    } else {
        FLVRNowPlayingWindowController* controller = [[FLVRNowPlayingWindowController alloc] initWithWindowNibName:@"NowPlaying"];
        [NSApp beginSheet:[controller window] modalForWindow:window modalDelegate:self didEndSelector:@selector(_nowPlayingSheetDidEnd:returnCode:contextInfo:) contextInfo:controller];
    }
}

- (void) alertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    if (NSAlertDefaultReturn == returnCode) {
        [[
            [NSAppleScript alloc] initWithSource:
                [NSString stringWithFormat:
                    @"tell application \"Safari\"\n"\
                    "  make new document at end of documents\n"\
                    "  set url of document 1 to \"http://www.tastyapps.com/\"\n"\
                    "end tell\n"
                ]
            ]
            executeAndReturnError:nil
        ];
    }
}

- (void) _optionsSheetDidEnd:(NSWindow*)window returnCode:(int)returnCode contextInfo:(FLVROptionsWindowController*)controller
{
    [window orderOut:nil];
    [controller release];
}

- (void) _nowPlayingSheetDidEnd:(NSWindow*)window returnCode:(int)returnCode contextInfo:(FLVRNowPlayingWindowController*)controller
{
    [window orderOut:nil];
    [controller release];
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
        NSLog(@"%@", script);
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
                NSLog(@"%@", script);
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


#ifdef DEBUG
- (BOOL) respondsToSelector:(SEL)selector
{
    NSLog(@"FLVR probed: %@", NSStringFromSelector(selector));
    return [super respondsToSelector:selector];
}
#endif

@end