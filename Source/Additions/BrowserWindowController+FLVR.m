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
#import "BrowserWindowController+FLVR.h"
#import "FLVRNowPlayingPanel.h"

@implementation BrowserWindowController (FLVR)

- (NSRect) FLVR_notPresent_window:(NSWindow*)window willPositionSheet:(NSWindow*)sheet usingRect:(NSRect)rect 
{
    return rect;
}

- (NSRect) FLVR_window:(NSWindow*)window willPositionSheet:(NSWindow*)sheet usingRect:(NSRect)r1 
{
    NSRect r2 = [self FLVR_window:window willPositionSheet:sheet usingRect:r1];
    if (NSEqualRects(r1, r2) && ([sheet isKindOfClass:[FLVRNowPlayingPanel class]] || [sheet class] == [NSPanel class])) {
        r2.origin.y -= 31;
    }
    return r2;
}

@end
