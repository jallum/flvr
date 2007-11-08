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

