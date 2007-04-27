#import "FLVRNowPlayingPanelThemeFrame.h"
//#import "B2TitleBarButtonCell.h"
#import "NSBezierPath+TastyApps.h"

@implementation FLVRNowPlayingPanelThemeFrame

- initWithFrame:(NSRect)frame styleMask:(int)sm owner:owner
{
	if (self = [super initWithFrame:frame styleMask:sm owner:owner]) {
		borderColor = [[NSColor colorWithCalibratedRed:.479182 green:.479182 blue:.479182 alpha:0.5] retain];
		contentFill = [[NSColor colorWithCalibratedWhite:0.0 alpha:1.0] retain];
	}
	return self;
}

- (void) dealloc
{
    [borderColor release];
    [contentFill release];
    [super dealloc];
}

- (NSRect) contentRect
{
    return NSInsetRect([self frame], 1.0, 1.0);
}

- contentFill
{
	return contentFill;
}

- borderColor
{
	return borderColor;
}

- (float) bottomCornerRadius
{
	return 6.5;
}

- (void) drawRect:(NSRect)rect
{
	NSRect frame = [self frame];

	[[[self contentFill] colorWithAlphaComponent:0.0] set];
	NSRectFill(frame);

    NSBezierPath* borderPath = [NSBezierPath bezierPathWithRoundedRect:frame cornerRadius:[self bottomCornerRadius] inCorners:TABottomLeftCorner | TABottomRightCorner];
	[borderPath setLineWidth:0];
	[borderPath setFlatness:0.2];
	[[[self contentFill] colorWithAlphaComponent:0.9] set];
	[borderPath fill];

    [NSGraphicsContext saveGraphicsState];
    NSBezierPath* dashedLines = [NSBezierPath bezierPath];
    [[NSColor grayColor] set];
    float pattern[] = {
        2.0,
        2.0,
    };
    [dashedLines setLineDash:pattern count:2 phase:0.0];
	[dashedLines setLineWidth:0];
    [dashedLines setFlatness:0.2];
    [dashedLines moveToPoint:NSMakePoint(NSMinX(frame), NSMinY(frame) + 40.0)];
    [dashedLines lineToPoint:NSMakePoint(NSMaxX(frame), NSMinY(frame) + 40.0)];
    [dashedLines moveToPoint:NSMakePoint(NSMinX(frame), NSMaxY(frame) - 54.0)];
    [dashedLines lineToPoint:NSMakePoint(NSMaxX(frame), NSMaxY(frame) - 54.0)];
    [dashedLines closePath];
    [[NSGraphicsContext currentContext] setShouldAntialias:NO];
    [dashedLines stroke];
    [NSGraphicsContext restoreGraphicsState];
    
	if ([[self class] respondsToSelector:@selector(drawBevel:inFrame:topCornerRounded:)]) {
		[[self class] drawBevel:rect inFrame:frame topCornerRounded:NO];
	}
}

/*
- (BOOL) preservesContentDuringLiveResize
{
	return NO;
}
*/

@end
