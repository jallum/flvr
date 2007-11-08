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
#import "FLVROptionsWindowController.h"
#import "FLVRNowPlayingPanel.h"

@implementation FLVROptionsWindowController

static NSArray* FORMATS;
static NSArray* AUDIO_CODECS;
static NSArray* AUDIO_BITRATES;
static NSArray* VIDEO_CODECS;
static NSArray* VIDEO_BITRATES;

+ (NSDictionary*) loadOptions
{
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults synchronize];
    NSDictionary* d = [userDefaults persistentDomainForName:@"com.tastyapps.flvr"];
    NSMutableDictionary* md = [NSMutableDictionary dictionary];
    NSEnumerator* e = [d keyEnumerator];
    NSString* k;
    while (k = [e nextObject]) {
        id v = [d objectForKey:k];
        if ([k hasPrefix:@"flvr."]) {
            k = [k substringFromIndex:5];
        }
        [md setObject:v forKey:k];
    }
    return md;
}

+ (void) saveOptions:(NSDictionary*)d
{
    NSMutableDictionary* md = [NSMutableDictionary dictionary];
    NSEnumerator* e = [d keyEnumerator];
    NSString* k;
    while (k = [e nextObject]) {
        id v = [d objectForKey:k];
        if (![k hasPrefix:@"flvr."]) {
            k = [NSString stringWithFormat:@"flvr.%@", k];
        }
        [md setObject:v forKey:k];
    }
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setPersistentDomain:md forName:@"com.tastyapps.flvr"];
    [userDefaults synchronize];
}

+ (void) initialize
{
    if (self == [FLVROptionsWindowController class]) {
        NSArray* dependencies = [NSArray arrayWithObject:@"options"];
        [self setKeys:dependencies triggerChangeNotificationsForDependentKey:@"destinationFolder"];
        [self setKeys:dependencies triggerChangeNotificationsForDependentKey:@"addToiTunes"];
        [self setKeys:dependencies triggerChangeNotificationsForDependentKey:@"sendToGrowl"];
        [self setKeys:dependencies triggerChangeNotificationsForDependentKey:@"selectedFormat"];
        [self setKeys:dependencies triggerChangeNotificationsForDependentKey:@"selectedVideoCodec"];
        [self setKeys:dependencies triggerChangeNotificationsForDependentKey:@"selectedVideoBitrate"];
        [self setKeys:dependencies triggerChangeNotificationsForDependentKey:@"selectedAudioCodec"];
        [self setKeys:dependencies triggerChangeNotificationsForDependentKey:@"selectedAudioBitrate"];
    
        FORMATS = [[NSArray alloc] initWithObjects:
            @".avi",
            @".flv",
            @".mov",
            @".mp4",
            nil
        ];

        VIDEO_CODECS = [[NSArray alloc] initWithObjects:
            @"h264",
            @"mpeg4",
            @"copy",
            nil
        ];

        VIDEO_BITRATES = [[NSArray alloc] initWithObjects:
            [NSNumber numberWithInt:200],
            [NSNumber numberWithInt:300],
            [NSNumber numberWithInt:400],
            [NSNumber numberWithInt:700],
            nil
        ];
        
        AUDIO_CODECS = [[NSArray alloc] initWithObjects:
            @"aac",
            @"mp3",
            @"copy",
            nil
        ];

        AUDIO_BITRATES = [[NSArray alloc] initWithObjects:
            [NSNumber numberWithInt:32],
            [NSNumber numberWithInt:64],
            [NSNumber numberWithInt:96],
            nil
        ];
    }
}

- (void) dealloc
{
    [options release];
    [super dealloc];
}

- (void) awakeFromNib
{
    [self setOptions:[FLVROptionsWindowController loadOptions]];
}

- (IBAction) cancel:(id)sender
{
    [NSApp endSheet:[self window]];
}

- (IBAction) close:(id)sender
{
    [FLVROptionsWindowController saveOptions:options];
    [NSApp endSheet:[self window]];
}

- (IBAction) changeDestinationFolder:(id)sender
{
    NSOpenPanel* openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseFiles:NO];
    [openPanel setCanCreateDirectories:YES];
    [openPanel setCanChooseDirectories:YES];
    if (NSOKButton == [openPanel runModalForDirectory:[[self destinationFolder] stringByExpandingTildeInPath] file:nil types:nil]) {
        [self setDestinationFolder:[[openPanel directory] stringByAbbreviatingWithTildeInPath]];
    }
}

- (IBAction) resetDestinationFolder:(id)sender
{
    [self setDestinationFolder:@"~/Movies"];
}

- (void) setSelectedFormat:(int)index
{
    [options setObject:[FORMATS objectAtIndex:index] forKey:@"format"];
}

- (int) selectedFormat
{
    return [FORMATS indexOfObject:[options objectForKey:@"format"]];
}

- (void) setSelectedVideoCodec:(int)index
{
    [options setObject:[VIDEO_CODECS objectAtIndex:index] forKey:@"videoCodec"];
}

- (int) selectedVideoCodec
{
    return [VIDEO_CODECS indexOfObject:[options objectForKey:@"videoCodec"]];
}

- (void) setSelectedVideoBitrate:(int)index
{
    [options setObject:[VIDEO_BITRATES objectAtIndex:index] forKey:@"videoBitrate"];
}

- (int) selectedVideoBitrate
{
    return [VIDEO_BITRATES indexOfObject:[options objectForKey:@"videoBitrate"]];
}

- (void) setSelectedAudioCodec:(int)index
{
    [options setObject:[AUDIO_CODECS objectAtIndex:index] forKey:@"audioCodec"];
}

- (int) selectedAudioCodec
{
    return [AUDIO_CODECS indexOfObject:[options objectForKey:@"audioCodec"]];
}

- (void) setSelectedAudioBitrate:(int)index
{
    [options setObject:[AUDIO_BITRATES objectAtIndex:index] forKey:@"audioBitrate"];
}

- (int) selectedAudioBitrate
{
    return [AUDIO_BITRATES indexOfObject:[options objectForKey:@"audioBitrate"]];
}

- (void) setDestinationFolder:(NSString*)destinationFolder
{
    [options setObject:destinationFolder forKey:@"destinationFolder"];
}

- (NSString*) destinationFolder
{
    return [options objectForKey:@"destinationFolder"];
}

- (void) setAddToiTunes:(BOOL)flag
{
    [options setObject:[NSNumber numberWithBool:flag] forKey:@"addToiTunes"];
}

- (BOOL) addToiTunes
{
    return [[options objectForKey:@"addToiTunes"] boolValue];
}

- (void) setSendToGrowl:(BOOL)flag
{
    [options setObject:[NSNumber numberWithBool:flag] forKey:@"sendToGrowl"];
}

- (BOOL) sendToGrowl
{
    return [[options objectForKey:@"sendToGrowl"] boolValue];
}

- (void) setOptions:(NSDictionary*)_options
{
    [options release];
    options = [_options mutableCopy];
}

- (NSDictionary*) options
{
    return options;
}

@end
