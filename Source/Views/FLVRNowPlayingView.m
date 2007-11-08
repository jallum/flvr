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
#import "FLVRNowPlayingView.h"
#import "FLVRVideoCell.h"
#import "FLVRScrollView.h"
#import "FLVRVideo.h"

@interface FLVRNowPlayingView (Private)

- (void) _restartTracking;
- (void) _layout;
- (void) _changeTrackingRectToCellAtPoint:(NSPoint)point;

@end

@implementation FLVRNowPlayingView

- (id) initWithFrame:(NSRect)frame 
{
    if (self = [super initWithFrame:frame mode:NSTrackModeMatrix cellClass:[FLVRVideoCell class] numberOfRows:1 numberOfColumns:2]) {
        [self setCellSize:NSMakeSize(300, 130)];
        [self setIntercellSpacing:NSMakeSize(10, 10)];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_restartTracking) name:NSViewFrameDidChangeNotification object:self];
        mouseOverTag = -1;
    }
    return self;
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self removeTrackingRect:trackingTag];
    [videos release];
    [super dealloc];
}

- (void) textDidEndEditing:(NSNotification *)notification;
{
    if ([[[notification userInfo] objectForKey:@"NSTextMovement"] intValue] == NSReturnTextMovement) {
        NSMutableDictionary *newUserInfo = [NSMutableDictionary dictionaryWithDictionary:[notification userInfo]];
        [newUserInfo setObject:[NSNumber numberWithInt:NSIllegalTextMovement] forKey:@"NSTextMovement"];
        notification = [NSNotification notificationWithName:[notification name] object:[notification object] userInfo:newUserInfo];
    }
    [super textDidEndEditing:notification];
}

- (void) setVideos:(NSArray*)_videos
{
    [videos release];
    videos = [_videos mutableCopy];
    [self _layout];
}

- (void) addVideo:(FLVRVideo*)video
{
    mouseOverTag = -1;
    if (!videos) {
        videos = [NSMutableArray arrayWithCapacity:10];
    }
    [videos insertObject:video atIndex:0];
    [self _layout];
}

- (void) removeVideo:(FLVRVideo*)video
{
    if (videos) {
        mouseOverTag = -1;
        [videos removeObject:video];
        [self _layout];
    }
}

- (void) updateCellForVideo:(FLVRVideo*)video
{
    NSCell* c = [self cellWithTag:[videos indexOfObject:video]];
    if (c) {
        [self drawCell:c];
    }
}

- (void) viewDidMoveToWindow
{
    [super viewDidMoveToWindow];
    if ([self window]) {
        [self _restartTracking];
    }
}

- (void) viewDidMoveToSuperview
{
    [super viewDidMoveToSuperview];
    NSScrollView* scrollView = [self enclosingScrollView];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:FLVRScrollViewChanged object:nil];
    if (scrollView) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_restartTracking) name:FLVRScrollViewChanged object:scrollView];
    }
}

- (BOOL) isFlipped
{
    return YES;
}

- (void) mouseEntered:(NSEvent*)event
{
    if ([event trackingNumber] == trackingTag) {
        [self _changeTrackingRectToCellAtPoint:[self convertPoint:[event locationInWindow] fromView:nil]];
    }
}

- (void) mouseExited:(NSEvent*)event
{
    if ([event trackingNumber] == trackingTag) {
        [self _changeTrackingRectToCellAtPoint:NSMakePoint(-1, -1)];
    } else if ([event trackingNumber] == cellTrackingTag) {
        [self _changeTrackingRectToCellAtPoint:[self convertPoint:[event locationInWindow] fromView:nil]];
    }
}

- (void) mouseDown:(NSEvent*)event
{
    NSPoint p = [self convertPoint:[[self window] convertScreenToBase:[NSEvent mouseLocation]] fromView:nil];
    [self _changeTrackingRectToCellAtPoint:p];
    [super mouseDown:event];
}

@end

@implementation FLVRNowPlayingView (Private)

- (void) _layout
{
    int count = [videos count];
    int numberOfColumns = [self numberOfColumns];
    int numberOfRows = (count / numberOfColumns) + ((count % numberOfColumns) ? 1 : 0);
    [self renewRows:numberOfRows columns:numberOfColumns];
    int x = 0, y = 0, i = 0;
    if (count) {
        id c = [self cellAtRow:y column:x++];
        [c setObjectValue:[videos objectAtIndex:i]];
        [c setTag:i++];
        while (i < count) {
            if (x == numberOfColumns) {
                x = 0;
                y++;
            }
            id c = [self cellAtRow:y column:x++];
            [c setObjectValue:[videos objectAtIndex:i]];
            [c setTag:i++];
        }
    }
    while (x < numberOfColumns) {
        id c = [self cellAtRow:y column:x++];
        [c setObjectValue:nil];
        [c setTag:i++];
    }
    [self sizeToCells];
    [self _restartTracking];
    [self setNeedsDisplay:YES];
}

- (void) _restartTracking
{
    NSRect rect = [self visibleRect];
    if (trackingTag) {
        [self removeTrackingRect:trackingTag];
    }    
    NSPoint p = [self convertPoint:[[self window] convertScreenToBase:[NSEvent mouseLocation]] fromView:nil];
    trackingTag = [self addTrackingRect:rect owner:self userData:NULL assumeInside:NSPointInRect(p, rect)];
    [self _changeTrackingRectToCellAtPoint:p];
}

- (void) _changeTrackingRectToCellAtPoint:(NSPoint)point
{
    int newCellTrackingTag = 0;
    int newTag = -1;
    
    /*  Tear down the old tracking rect, if any.
     */
    int oldX, oldY;
    [self getRow:&oldY column:&oldX ofCell:[self cellWithTag:mouseOverTag]];
    if (cellTrackingTag) {
        [self removeTrackingRect:cellTrackingTag];
    }

    /*  Setup a new tracking rect for the given point, if any.
     */
    int newX, newY;
    if ([self getRow:&newY column:&newX forPoint:point]) {
        NSSize intercellSpacing = [self intercellSpacing];
        NSRect cellFrame = NSIntersectionRect(NSInsetRect([self cellFrameAtRow:newY column:newX], -intercellSpacing.width, -intercellSpacing.height), [self visibleRect]);
        newCellTrackingTag = [self addTrackingRect:cellFrame owner:self userData:NULL assumeInside:YES];
        newTag = [[self cellAtRow:newY column:newX] tag];
    }
    
    /*  Distribute events as appropriate.
     */
    if (mouseOverTag != newTag) {
        if (mouseOverTag != -1) {
            [self highlightCell:NO atRow:oldY column:oldX];
        }
        if (newTag != -1) {
            [self highlightCell:YES atRow:newY column:newX];
        }
    }

    cellTrackingTag = newCellTrackingTag;
    mouseOverTag = newTag;
}

@end
