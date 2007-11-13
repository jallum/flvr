#import "DragDropTargetView.h"
#import "NSBezierPath+TastyApps.h"

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
		NSBezierPath* path = [NSBezierPath bezierPathWithRoundedRect:NSInsetRect(bounds, 10, 10) cornerRadius:10.0 inCorners:TATopLeftCorner | TABottomLeftCorner | TATopRightCorner | TABottomRightCorner];
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

	[self _beginHighlightAnimation];

    return [urls count] ? NSDragOperationCopy : NSDragOperationNone;
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
