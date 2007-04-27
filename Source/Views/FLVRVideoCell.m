#import "FLVR.h"
#import "FLVRVideoCell.h"
#import "FLVRVideo.h"
#import "FLVRNowPlayingView.h"
#import "NSImage+TastyApps.h"
#import "NSBezierPath+TastyApps.h"

#define NSOffsetPoint(p, xO, yO)  NSMakePoint(p.x + xO, p.y + yO)

#pragma mark -
@interface FLVRVideoCell (Private)
- (void) _beginEncoding:(id)sender;
- (NSRect) _cellFrameForFilename:(NSRect)cellFrame;
- (NSRect) _cellFrameForDuration:(NSRect)cellFrame;
- (NSRect) _cellFrameForVideoInfo:(NSRect)cellFrame;
- (NSRect) _cellFrameForAudioInfo:(NSRect)cellFrame;
- (NSRect) _cellFrameForEncodeButton:(NSRect)cellFrame;
- (NSRect) _cellFrameForCancelButton:(NSRect)cellFrame;
@end

#pragma mark -
@implementation FLVRVideoCell

+ (NSImage*) buildThumbnailFromImage:(NSImage*)image
{
    NSImage* newThumbnail = [[NSImage alloc] initWithSize:NSMakeSize(110, (int)(110/1.33))];
    NSRect r = NSMakeRect(0, 0, [newThumbnail size].width, [newThumbnail size].height);
    [newThumbnail lockFocus];
    [[NSColor darkGrayColor] set];
    [[NSBezierPath bezierPathWithRect:r] fill];
    [image drawInRect:NSInsetRect(r, 1, 1) fromRect:NSMakeRect(0, 0, [image size].width, [image size].height) operation:NSCompositeSourceOver fraction:1.0];
    [newThumbnail unlockFocus];
    return [newThumbnail autorelease];
}

+ (NSButtonCell*) buttonCellForImageNamed:(NSString*)name target:(id)target action:(SEL)action
{
    NSImage* image = [NSImage imageNamed:name forClass:[FLVRVideoCell class]];
    NSImage* altImage = [[NSImage alloc] initWithSize:[image size]];
    [altImage lockFocus];
    [image compositeToPoint:NSMakePoint(0,0) operation:NSCompositeSourceOver fraction:0.7];
    [altImage unlockFocus];

    NSButtonCell* button = [[NSButtonCell alloc] initImageCell:image];
    [button setAlternateImage:altImage];
    [button setButtonType:NSMomentaryChangeButton];
    [button setImagePosition:NSImageOnly];
    [button setBordered:NO];
    [button setTarget:target];
    [button setAction:action];

    return [button autorelease];
}

//  -------------------------------------------------------------------------

- (id) init
{
    if (self = [super init]) {
        [self setEnabled:YES];
        [self setEditable:NO];
        [self setFocusRingType:NSFocusRingTypeNone];
        [self setLineBreakMode:NSLineBreakByTruncatingTail];

        encodeButton = [[FLVRVideoCell buttonCellForImageNamed:@"Download" target:self action:@selector(_beginEncoding:)] retain];
        revealButton = [[FLVRVideoCell buttonCellForImageNamed:@"RevealInFinder" target:self action:@selector(_revealInFinder:)] retain];
        cancelButton = [[FLVRVideoCell buttonCellForImageNamed:@"Cancel" target:self action:@selector(_cancel:)] retain];

        filenameCell = [[NSTextFieldCell alloc] init];
        [filenameCell setTextColor:[NSColor whiteColor]];
        [filenameCell setEnabled:YES];
        [filenameCell setEditable:NO];
        [filenameCell setLineBreakMode:NSLineBreakByTruncatingTail];

        durationCell = [[NSTextFieldCell alloc] init];
        [durationCell setFont:[NSFont messageFontOfSize:9.0]];
        [durationCell setTextColor:[NSColor whiteColor]];
        [durationCell setLineBreakMode:NSLineBreakByTruncatingTail];

        videoInfoCell = [[NSTextFieldCell alloc] init];
        [videoInfoCell setFont:[NSFont messageFontOfSize:9.0]];
        [videoInfoCell setTextColor:[NSColor whiteColor]];
        [videoInfoCell setLineBreakMode:NSLineBreakByTruncatingTail];

        audioInfoCell = [[NSTextFieldCell alloc] init];
        [audioInfoCell setFont:[NSFont messageFontOfSize:9.0]];
        [audioInfoCell setTextColor:[NSColor whiteColor]];
        [audioInfoCell setLineBreakMode:NSLineBreakByTruncatingTail];
    }
    return self;
}

- (void) dealloc
{
    [audioInfoCell release];
    [videoInfoCell release];
    [durationCell release];
    [filenameCell release];
    [cancelButton release];
    [encodeButton release];
    [revealButton release];
    [super dealloc];
}

- (void) setRepresentedObject:(id)object
{
    [super setRepresentedObject:object];
    [thumbnail release];
    [reflection release];
    if (object) {
        thumbnail = [[FLVRVideoCell buildThumbnailFromImage:[object firstFrame]] retain];
        reflection = [[NSImage reflectedImage:thumbnail amountReflected:0.4] retain];
    } else {
        thumbnail = nil;
        reflection = nil;
    }
}

- (BOOL) hasValidObjectValue
{
    return [self representedObject] != nil;
}

- (void) setObjectValue:(id)value
{
    if (!value) {
        [self setRepresentedObject:nil];
    } else if ([value isKindOfClass:[FLVRVideo class]]) {
        [self setRepresentedObject:value];
        [filenameCell setStringValue:[value filename]];
        [super setObjectValue:[value filename]];
    } else if ([value isKindOfClass:[NSString class]]) {
        [[self representedObject] setFilename:value];
        [filenameCell setStringValue:value];
        [super setObjectValue:value];
    }
}

- (NSString*) stringValue
{
    return [self representedObject] ? [[self representedObject] filename] : @"";
}

- (id) objectValue
{
    return [self representedObject];
}

- (BOOL) trackMouse:(NSEvent*)event inRect:(NSRect)cellFrame ofView:(NSView*)view untilMouseUp:(BOOL)flag
{
    NSPoint point = [view convertPoint:[event locationInWindow] fromView:nil];
    FLVRVideo* video = [self representedObject];
    if (video) {
        NSRect cellFrameForCancelButton = [self _cellFrameForCancelButton:cellFrame];
        if ([self isHighlighted] && NSPointInRect(point, cellFrameForCancelButton)) {
            [cancelButton highlight:YES withFrame:cellFrame inView:view];
            BOOL result = [cancelButton trackMouse:event inRect:cellFrameForCancelButton ofView:view untilMouseUp:YES];
            [cancelButton highlight:NO withFrame:cellFrame inView:view];
            return result;
        }
    
        NSRect cellFrameForEncodeButton = [self _cellFrameForEncodeButton:cellFrame];
        if ([self isHighlighted] && [video state] == FLVRVideoDownloading && [video shouldAllowCancel] && NSPointInRect(point, cellFrameForEncodeButton)) {
            [encodeButton highlight:YES withFrame:cellFrameForEncodeButton inView:view];
            BOOL result = [encodeButton trackMouse:event inRect:cellFrameForEncodeButton ofView:view untilMouseUp:YES];
            [encodeButton highlight:NO withFrame:cellFrameForEncodeButton inView:view];
            return result;
        }

        NSRect cellFrameForRevealButton = [self _cellFrameForEncodeButton:cellFrame];
        if ([self isHighlighted] && [video state] == FLVRVideoFinished && NSPointInRect(point, cellFrameForEncodeButton)) {
            [revealButton highlight:YES withFrame:cellFrameForRevealButton inView:view];
            BOOL result = [revealButton trackMouse:event inRect:cellFrameForRevealButton ofView:view untilMouseUp:YES];
            [revealButton highlight:NO withFrame:cellFrameForRevealButton inView:view];
            return result;
        }
    
        NSRect cellFrameForFilename = [self _cellFrameForFilename:cellFrame];
        if (NSPointInRect(point, cellFrameForFilename) && [video state] == FLVRVideoDownloading) {
            [self setEditable:YES];
            [self setFocusRingType:NSFocusRingTypeDefault];
            [self selectWithFrame:cellFrameForFilename inView:view editor:[self setUpFieldEditorAttributes:[[view window] fieldEditor:YES forObject:self]] delegate:view start:0 length:[[video filename] length]];
            return YES;
        }
    }
    return NO;
}

//  -------------------------------------------------------------------------

- (NSText*) setUpFieldEditorAttributes:(NSText*)text
{
    text = [super setUpFieldEditorAttributes:text];
    [text setDrawsBackground:YES];
    [text setBackgroundColor:[NSColor whiteColor]];
    [text setTextColor:[NSColor blackColor]];
    return text;
}

- (void) endEditing:(NSText*)text
{
    [super endEditing:text];
    [self setFocusRingType:NSFocusRingTypeNone];
    [self setEditable:NO];
}

- (void) drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView*)controlView
{
    FLVRVideo* video = [self representedObject];
    if (!video) {
        return;
    }
    NSDictionary* info = [video info];

    /*
     */
    [thumbnail compositeToPoint:NSMakePoint(NSMinX(cellFrame) + 10.0, NSMinY(cellFrame) + ([thumbnail size].height + 10.0)) operation:NSCompositeSourceOver];
    [reflection compositeToPoint:NSMakePoint(NSMinX(cellFrame) + 10.0, NSMinY(cellFrame) + ([thumbnail size].height * 2 + 10.0)) operation:NSCompositeSourceOver];

    /*
     */
    [filenameCell drawInteriorWithFrame:[self _cellFrameForFilename:cellFrame] inView:controlView];

    /*
     */
    float duration = [[info objectForKey:@"duration"] floatValue];
    NSString* durationAsString = @"--:--";
    if (duration > 0) {
        int hours = (int)(duration / 60 / 60);
        int minutes = (int)((duration - hours) / 60);
        float seconds = fmod(duration, 60);
        if (hours) {
            durationAsString = [NSString stringWithFormat:@"%02d:%02d:%02d.%1d", hours, minutes, (int)seconds, (int)((seconds - (int)seconds) * 10)];
        } else {
            durationAsString = [NSString stringWithFormat:@"%02d:%02d.%1d", minutes, (int)seconds, (int)((seconds - (int)seconds) * 10)];
        }
    }
    [durationCell setStringValue:durationAsString];
    [durationCell drawInteriorWithFrame:[self _cellFrameForDuration:cellFrame] inView:controlView];

    /*
     */
    NSString* videoInfoAsString = FLVRLocalizedString(@"N/A", @"");
    if ([info objectForKey:@"videoCodec"]) {
        videoInfoAsString = [NSString stringWithFormat:@"%@ @ %@ %@", [info objectForKey:@"videoCodec"], [info objectForKey:@"videoFrameRate"], FLVRLocalizedString(@"fps", @"")];
    }
    [videoInfoCell setStringValue:videoInfoAsString];
    [videoInfoCell drawInteriorWithFrame:[self _cellFrameForVideoInfo:cellFrame] inView:controlView];

    /*
     */
    NSString* audioInfoAsString = FLVRLocalizedString(@"N/A", @"");
    if ([info objectForKey:@"audioCodec"]) {
        audioInfoAsString = [NSString stringWithFormat:@"%@ %@/%g%@", [info objectForKey:@"audioCodec"], (([[info objectForKey:@"audioChannels"] intValue] == 1) ? FLVRLocalizedString(@"Mono",@"") : FLVRLocalizedString(@"Stereo",@"")), [[info objectForKey:@"audioSamplingRate"] floatValue] / 1000.0, FLVRLocalizedString(@"kHz", @"")];
    }
    [audioInfoCell setStringValue:audioInfoAsString];
    [audioInfoCell drawInteriorWithFrame:[self _cellFrameForAudioInfo:cellFrame] inView:controlView];

    /*
     */
    NSPoint c = NSMakePoint(NSMinX(cellFrame) + 63.5, NSMinY(cellFrame) + 50.5);
    NSColor* color;
    float percent = 1.0;
    if ([video state] == FLVRVideoDownloading) {
        percent = [video percentDownloaded];
        if ([video shouldAllowCancel]) {
            color = [NSColor grayColor];
        } else {
            color = [NSColor orangeColor];
        }
    } else {
        percent = [video percentEncoded];
        color = [NSColor greenColor];
    }

    /*
     */
    if ([self isHighlighted] && [video state] == FLVRVideoDownloading && [video shouldAllowCancel]) {
        [encodeButton drawInteriorWithFrame:[self _cellFrameForEncodeButton:cellFrame] inView:controlView];
    } else if ([self isHighlighted] && [video state] == FLVRVideoFinished) {
        [revealButton drawInteriorWithFrame:[self _cellFrameForEncodeButton:cellFrame] inView:controlView];
    } else {
        NSBezierPath* completed = nil;
        if ([video state] != FLVRVideoFinished) {
            completed = [NSBezierPath circleSegmentWithCenter:c startAngle:270 endAngle:270 + (360 * percent) smallRadius:7.0 bigRadius:25];
        } else if (percent > 0.0) {
            completed = [NSBezierPath bezierPath];
            [completed appendBezierPathWithArcWithCenter:c radius:25 startAngle:0.0 endAngle:360.0];
        }
        [color set];
        [completed fill];

        [[NSColor whiteColor] set];

        NSBezierPath* bezel = [NSBezierPath bezierPath];
        [bezel setLineWidth:3.0];
        [bezel appendBezierPathWithArcWithCenter:c radius:25 startAngle:0 endAngle:360.0];
        [bezel stroke];

        if ([video state] != FLVRVideoFinished) {
            NSBezierPath* innerBezel = [NSBezierPath bezierPath];
            [innerBezel appendBezierPathWithArcWithCenter:c radius:7.0 startAngle:0 endAngle:360.0];
            [innerBezel setLineWidth:2.0];
            [innerBezel stroke];
        } else {
            NSAttributedString* checkMarkString = [[NSAttributedString alloc] 
                initWithString:[NSString stringWithCString:"✓" encoding:NSUTF8StringEncoding]
                attributes:[NSDictionary dictionaryWithObjectsAndKeys:
                    [NSColor whiteColor], NSForegroundColorAttributeName,
                    [NSFont messageFontOfSize:33.0], NSFontAttributeName, 
                    nil
                ]
            ];
            [checkMarkString drawAtPoint:NSOffsetPoint(c, -12.0, -19.25)];
        }
    }

    if ([self isHighlighted]) {
        [cancelButton drawInteriorWithFrame:[self _cellFrameForCancelButton:cellFrame] inView:controlView];
    }
}

@end

@implementation FLVRVideoCell (Private)

- (void) _beginEncoding:(id)sender
{
    [[self representedObject] beginEncoding];
}

- (void) _revealInFinder:(id)sender
{
    id controlView = [self controlView];
    if ([controlView respondsToSelector:@selector(delegate)]) {
        id delegate = [controlView delegate];
        if ([delegate respondsToSelector:@selector(revealInFinder:)]) {
            [delegate revealInFinder:[self representedObject]];
        }
    }
}

- (void) _cancel:(id)sender
{
    [[self representedObject] cancel];
}

- (NSRect) _cellFrameForFilename:(NSRect)cellFrame
{
    float x = NSMinX(cellFrame) + 10.0 + [thumbnail size].width + 3.5;
    return NSMakeRect(
        x,
        NSMinY(cellFrame) + 7.0,
        NSWidth(cellFrame) - (x - NSMinX(cellFrame)),
        17.0
    );
}

- (NSRect) _cellFrameForDuration:(NSRect)cellFrame
{
    float x = NSMinX(cellFrame) + 10.0 + [thumbnail size].width + 3.5;
    return NSMakeRect(
        x,
        NSMinY(cellFrame) + 7.0 + 17.0,
        NSWidth(cellFrame) - (x - NSMinX(cellFrame)),
        12.0
    );
}

- (NSRect) _cellFrameForVideoInfo:(NSRect)cellFrame
{
    float x = NSMinX(cellFrame) + 10.0 + [thumbnail size].width + 3.5;
    return NSMakeRect(
        x,
        NSMinY(cellFrame) + 7.0 + 17.0 + 12.0,
        NSWidth(cellFrame) - (x - NSMinX(cellFrame)),
        12.0
    );
}

- (NSRect) _cellFrameForAudioInfo:(NSRect)cellFrame
{
    float x = NSMinX(cellFrame) + 10.0 + [thumbnail size].width + 3.5;
    return NSMakeRect(
        x,
        NSMinY(cellFrame) + 7.0 + 17.0 + 12.0 + 12.0,
        NSWidth(cellFrame) - (x - NSMinX(cellFrame)),
        12.0
    );
}

- (NSRect) _cellFrameForEncodeButton:(NSRect)cellFrame
{
    return NSMakeRect(
        NSMinX(cellFrame) + 10.0 + (([thumbnail size].width - [encodeButton cellSize].width) / 2), 
        NSMinY(cellFrame) + 10.0 + (([thumbnail size].height - [encodeButton cellSize].height) / 2),
        [encodeButton cellSize].width,
        [encodeButton cellSize].height
    );
}

- (NSRect) _cellFrameForCancelButton:(NSRect)cellFrame
{
    return NSMakeRect(
        NSMinX(cellFrame) + 14.0 - ([cancelButton cellSize].width / 2), 
        NSMinY(cellFrame) + 14.0 - ([cancelButton cellSize].height / 2),
        [cancelButton cellSize].width,
        [cancelButton cellSize].height
    );
}

@end
