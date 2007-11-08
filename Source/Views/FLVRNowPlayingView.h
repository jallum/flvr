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
#import <Cocoa/Cocoa.h>

@class FLVRVideo;

@interface FLVRNowPlayingView : NSMatrix {
    int trackingTag;
    int cellTrackingTag;
    int mouseOverTag;
    /**/
    NSMutableArray* videos;
}

- (void) setVideos:(NSArray*)videos;
- (void) addVideo:(FLVRVideo*)video;
- (void) removeVideo:(FLVRVideo*)video;
- (void) updateCellForVideo:(FLVRVideo*)video;

@end

@interface NSObject (FLVRNowPlayingViewDelegate)
- (void) revealInFinder:(FLVRVideo*)video;
@end