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
#import "FLVRNowPlayingPanel.h"
#import "FLVRNowPlayingPanelThemeFrame.h"

@interface NSWindow (Private)
+ (Class) frameViewClassForStyleMask:(unsigned int)mask;
@end

@interface FLVRNowPlayingPanel (Private)
- (void) setupAppearance;
@end

@implementation FLVRNowPlayingPanel

+ (Class) frameViewClassForStyleMask:(unsigned int)styleMask
{
	return [FLVRNowPlayingPanelThemeFrame class];
}

- (void) keyDown:(NSEvent*)event
{
    NSString *chars = [event characters];
    unichar character = [chars characterAtIndex: 0];

    if (character == 27 && [[self delegate] respondsToSelector:@selector(close:)]) {
        [[self delegate] close:nil];
    } else {
        [super keyDown:event];
    }
}

@end
