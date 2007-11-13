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
#import <Cocoa/Cocoa.h>

typedef enum _SACornerTypes {
	SATopLeftCorner = 1,
	SABottomLeftCorner = 2,
	SATopRightCorner = 4,
	SABottomRightCorner = 8
} SACornerType;

@interface NSBezierPath (SourApps)

+ (NSPoint) pointWithPolarCenter:(NSPoint)center radius:(float)r angle:(float)deg;
+ (NSBezierPath*) circleSegmentWithCenter:(NSPoint)center startAngle:(float)a1 endAngle:(float)a2 smallRadius:(float)r1 bigRadius:(float)r2;
+ (NSBezierPath *) bezierPathWithRoundedRect:(NSRect)aRect cornerRadius:(float)radius inCorners:(SACornerType)corners;
+ (NSBezierPath*)bezierPathWithRoundedRect:(NSRect)aRect cornerRadius:(float)radius;

@end