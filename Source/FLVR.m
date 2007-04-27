#import "FLVR.h"
#import <openssl/rsa.h>
#import <openssl/sha.h>
#import <objc/objc-class.h>
#import <Carbon/Carbon.h>
//#import "BrowserWindowController+FLVR.h"
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

static NSDictionary* loadParameters()
{
    RSA* rsaKey = RSA_new();

    /*  Create the public key.
     */
    unsigned char RSA_N[] = {
        0xc5, 0xcd, 0xfe, 0xdb, 0x5b, 0x89, 0xed, 0x07 ^ 'F',
        0xb0, 0x73, 0xd9, 0x17, 0xa1, 0xd1, 0xc1, 0xf0 ^ 'L',
        0x0f, 0x7c, 0xce, 0x28, 0x71, 0x8d, 0xd0, 0x14 ^ 'V',
        0x43, 0xd0, 0xf3, 0x4f, 0x8e, 0x76, 0xf9, 0x4f ^ 'R',
        0xf4, 0x21, 0x0e, 0x9a, 0x37, 0xe0, 0x84, 0xb2 ^ ' ',
        0xb5, 0x64, 0x82, 0x94, 0xe5, 0x4b, 0x1f, 0x63 ^ '0',
        0xdc, 0x69, 0x02, 0x93, 0x2e, 0xe1, 0x9b, 0x1b ^ '.',
        0x82, 0x52, 0x40, 0xa3, 0x88, 0x4b, 0xa0, 0xc0 ^ '9',
        0x2e, 0x95, 0x7a, 0x0a, 0x58, 0xc7, 0xa0, 0xa7 ^ 'B',
        0x32, 0x83, 0x03, 0x0d, 0x0f, 0xdf, 0x6a, 0xa5 ^ 'E',
        0x44, 0xc0, 0xa8, 0x74, 0xae, 0x4d, 0xc2, 0xca ^ 'T',
        0x7c, 0x0d, 0xaa, 0x63, 0x24, 0x58, 0xc0, 0x72 ^ 'A',
        0xed, 0xd0, 0x94, 0xd2, 0x20, 0xa1, 0xd7, 0xe1 ^ ' ',
        0x63, 0x34, 0x05, 0x24, 0xf5, 0x14, 0x74, 0x3e ^ '6',
        0xa6, 0x48, 0x72, 0x69, 0x65, 0x8b, 0xce, 0xb4 ^ ' ',
        0xc1, 0x46, 0x28, 0x47, 0xca, 0x93, 0xcd, 0x17 ^ ' ',
    };
    char* salt = "FLVR 0.9BETA 6  ";
    for (int i = 0, imax = strlen(salt); i < imax; i++) {
        RSA_N[((i + 1) << 3) - 1] ^= salt[i];
    }
    rsaKey->n = BN_bin2bn(RSA_N, sizeof(RSA_N), NULL);

    /*  Create the exponent.
     */
    unsigned char RSA_E[] = {
        0x03
    };
	rsaKey->e = BN_bin2bn(RSA_E, sizeof(RSA_E), NULL);

    /*  Load the license file, and check it for basic validity.
     */
    CFMutableDictionaryRef myDict = nil;
	CFDataRef data;
	SInt32 errorCode;
	NSString* licenseFile = [[NSBundle bundleForClass:[FLVR class]] pathForResource:@"license" ofType:@"plist"];
	if (!licenseFile || !CFURLCreateDataAndPropertiesFromResource(kCFAllocatorDefault, (CFURLRef)[NSURL fileURLWithPath:licenseFile], &data, NULL, NULL, &errorCode) || errorCode) {
        RSA_free(rsaKey);
        return NULL;
    } else {
        CFStringRef errorString = NULL;
        myDict = (CFMutableDictionaryRef)CFPropertyListCreateFromXMLData(kCFAllocatorDefault, data, kCFPropertyListMutableContainers, &errorString);
        CFRelease(data);
        data = NULL;
        if (errorString || CFDictionaryGetTypeID() != CFGetTypeID(myDict) || !CFPropertyListIsValid(myDict, kCFPropertyListXMLFormat_v1_0)) {
            CFRelease(myDict);
            RSA_free(rsaKey);
            return NULL;
        }
    }
    
    /*  Extract the signature.
     */
    unsigned char sigBytes[128];
    if (!CFDictionaryContainsKey(myDict, CFSTR("Signature"))) {
        CFRelease(myDict);
        RSA_free(rsaKey);
        return NULL;
    } else {
        CFDataRef sigData = CFDictionaryGetValue(myDict, CFSTR("Signature"));
        CFDataGetBytes(sigData, CFRangeMake(0, 128), sigBytes);
        CFDictionaryRemoveValue(myDict, CFSTR("Signature"));
    }
    
    /*  Decrypt the signature.
     */
    unsigned char checkDigest[128] = {0};
    if (RSA_public_decrypt(128, sigBytes, checkDigest, rsaKey, RSA_PKCS1_PADDING) != SHA_DIGEST_LENGTH) {
        CFRelease(myDict);
        RSA_free(rsaKey);
        return NULL;
    } else {
        RSA_free(rsaKey);
        rsaKey = NULL;
    }
    
    /*  Get the number of elements, Load the keys and build up the key array.
     */
    CFIndex count = CFDictionaryGetCount(myDict);
    CFMutableArrayRef keyArray = CFArrayCreateMutable(kCFAllocatorDefault, count, NULL);
    CFStringRef keys[count];
    CFDictionaryGetKeysAndValues(myDict, (const void**)&keys, NULL);
    for (int i = 0; i < count; i++) {
        CFArrayAppendValue(keyArray, keys[i]);
    }

    /*  Sort the array, so that we'll have consistent hashes.
     */
    int context = kCFCompareCaseInsensitive;
    CFArraySortValues(keyArray, CFRangeMake(0, count), (CFComparatorFunction)CFStringCompare, &context);
    
    /*  Hash the keys and values.
     */
    SHA_CTX ctx;
    SHA1_Init(&ctx);
    for (int i = 0; i < count; i++) {
        char *valueBytes;
        int valueLengthAsUTF8;
        CFStringRef key = CFArrayGetValueAtIndex(keyArray, i);
        CFStringRef value = CFDictionaryGetValue(myDict, key);

        // Account for the null terminator
        valueLengthAsUTF8 = CFStringGetMaximumSizeForEncoding(CFStringGetLength(value), kCFStringEncodingUTF8) + 1;
        valueBytes = (char *)malloc(valueLengthAsUTF8);
        CFStringGetCString(value, valueBytes, valueLengthAsUTF8, kCFStringEncodingUTF8);
        SHA1_Update(&ctx, valueBytes, strlen(valueBytes));
        free(valueBytes);
    }
    unsigned char digest[SHA_DIGEST_LENGTH];
    SHA1_Final(digest, &ctx);
    
    if (keyArray != nil) {
        CFRelease(keyArray);
    }
    
    /*  Check if the signature is a match.
     */
    for (int i = 0; i < SHA_DIGEST_LENGTH; i++) {
        if (checkDigest[i] ^ digest[i]) {
            CFRelease(myDict);
            return NULL;
        }
    }

    return (NSDictionary*)myDict;
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

    /*  De-Obfuscate our init routine.
     */
    swapInstanceImplementations(
        [FLVR class],
        @selector(init),
        @selector(initWithParameters:)
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

- (id) initWithParameters:(NSMutableDictionary*)_parameters
{
    if (self = [super init]) {
        parameters = loadParameters();
#ifdef DEBUG
        NSLog(@"parameters = %@", parameters);
#endif
    }
    return self;
}

- (id) init
{
    if (self = [super init]) {
    }
    return self;
}

- (void) dealloc
{
    [parameters release];
    [super dealloc];
}

- (NSDictionary*) parameters
{
    return [[parameters retain] autorelease];
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
    NSDate* expiresOn = nil;
    if (!parameters) {
        /*  No parameters.  The application and/or license file has 
         *  most likely been tampered with...  Let them know that we're
         *  not happy.
         */
        NSAlert* alert = [NSAlert alertWithMessageText:FLVRLocalizedString(@"This beta of FLVR has been corrupted.", @"") defaultButton:nil alternateButton:FLVRLocalizedString(@"No Thanks", "") otherButton:nil informativeTextWithFormat:FLVRLocalizedString(@"A new beta - or possibly the final release - can be found on the TastyApps website, at http://www.tastyapps.com.  Would you like to go there now?", @"")];
        [alert setIcon:[[[NSImage alloc] initByReferencingFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"FLVR" ofType:@"icns"]] autorelease]];
        [alert setAlertStyle:NSCriticalAlertStyle];
        [alert beginSheetModalForWindow:window modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:nil];
    } else if ([parameters objectForKey:@"Expires"] && (!(expiresOn = [NSDate dateWithString:[parameters objectForKey:@"Expires"]]) || (expiresOn == [[NSDate date] earlierDate:expiresOn]))) {
        /*  There was an expiration date in the parameters, and it's 
         *  passed.  Let them know that they should pay up...  in a 
         *  nice way.
         */
        NSAlert* alert = [NSAlert alertWithMessageText:FLVRLocalizedString(@"This beta of FLVR has expired.", @"") defaultButton:nil alternateButton:FLVRLocalizedString(@"No Thanks", "") otherButton:nil informativeTextWithFormat:FLVRLocalizedString(@"A new beta - or possibly the final release - can be found on the TastyApps website, at http://www.tastyapps.com.  Would you like to go there now?", @"")];
        [alert setIcon:[[[NSImage alloc] initByReferencingFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"FLVR" ofType:@"icns"]] autorelease]];
        [alert beginSheetModalForWindow:window modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:nil];
    } else if (GetCurrentKeyModifiers() & (1 << optionKeyBit)) {
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