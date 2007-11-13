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
 * MERCHANSABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, 
 * USA.
 */
#import "DragDropTargetView.h"
#import "NSBezierPath+SourApps.h"

@implementation DragDropTargetView

- (id) initWithFrame:(NSRect)frame 
{
    if (self = [super initWithFrame:frame]) {
        [self registerForDraggedTypes:[NSArray arrayWithObjects:NSURLPboardType, nil]];
    }
    return self;
}

- (void) drawRect:(NSRect)rect
{
	if (_highlighted) {
		[NSGraphicsContext saveGraphicsState];
		[[NSGraphicsContext currentContext] setShouldAntialias:YES];

		NSRect bounds = [self bounds];
		[[NSColor colorWithCalibratedWhite:0.2 alpha:1.0] set];
		NSBezierPath* path = [NSBezierPath bezierPathWithRoundedRect:NSInsetRect(bounds, 10, 10) cornerRadius:10.0 inCorners:SATopLeftCorner | SABottomLeftCorner | SATopRightCorner | SABottomRightCorner];
		float lineDash[2];
		lineDash[0] = 20.0;
		lineDash[1] = 5.0;
		[path setLineDash:lineDash count:2 phase:_phase];
		[path setFlatness:0.0];    
		[path setLineWidth:2.5];
		[path stroke];

		[NSGraphicsContext restoreGraphicsState];
	}
}

- (void) _updatePhase
{
	_phase = (_phase + 3) % 25;
	[self setNeedsDisplay:YES];
}

- (void) _beginHighlightAnimation
{
	_highlighted = YES;
	_timer = [[NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(_updatePhase) userInfo:nil repeats:YES] retain];
	[self setNeedsDisplay:YES];
}

- (void) _endHighlightAnimation
{
	_highlighted = NO;
	[_timer invalidate];
	[_timer release];
	_timer = nil;
	[self setNeedsDisplay:YES];
}

- (NSDragOperation) draggingEntered:(id <NSDraggingInfo>)sender 
{
    NSPasteboard *pb = [sender draggingPasteboard];
    NSArray *urls = [pb propertyListForType:NSURLPboardType];
    if ([urls count] && [[urls objectAtIndex:0] hasPrefix:@"http://"]) {
        [self _beginHighlightAnimation];
        return NSDragOperationCopy;
    } else {
        return NSDragOperationNone;
    }
}

- (void)draggingExited:(id <NSDraggingInfo>)sender
{
	[self _endHighlightAnimation];
}

- (BOOL) performDragOperation:(id <NSDraggingInfo>)sender 
{
	[self _endHighlightAnimation];

    NSPasteboard *pb = [sender draggingPasteboard];
    NSArray *urls = [pb propertyListForType:NSURLPboardType];
    BOOL didPerformDragOperation = NO;
    if ([urls count]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"UrlDropped" object:nil userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
            [urls objectAtIndex:0],
            @"url",
            nil
        ]];
		didPerformDragOperation = YES;
    }
    return didPerformDragOperation;
}

@end
