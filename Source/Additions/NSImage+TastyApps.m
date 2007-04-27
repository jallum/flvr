#import "NSImage+TastyApps.h"
#import "CTGradient.h"

@implementation NSImage (TastyApps)

+ (NSImage*) imageNamed:(NSString*)name forClass:(Class)inClass
{
    return [[NSImage alloc] initWithContentsOfFile:[[NSBundle bundleForClass:inClass] pathForImageResource:name]];
}

+ (NSImage*) reflectedImage:(NSImage*)sourceImage amountReflected:(float)fraction
{
	NSImage *reflection = [[NSImage alloc] initWithSize:[sourceImage size]];
	[reflection setFlipped:YES];
	[reflection lockFocus];
	CTGradient *fade = [CTGradient gradientWithBeginningColor:[NSColor colorWithCalibratedWhite:1.0 alpha:0.5] endingColor:[NSColor clearColor]];
	[fade fillRect:NSMakeRect(0, 0, [sourceImage size].width, [sourceImage size].height*fraction) angle:90.0];	
	[sourceImage drawAtPoint:NSMakePoint(0,0) fromRect:NSZeroRect operation:NSCompositeSourceIn fraction:1.0];
	[reflection unlockFocus];
	return [reflection autorelease];
}

@end

