#import "NSBezierPath+TastyApps.h"

@implementation NSBezierPath (TastyApps)

// Make a NSPoint with polar coordinates
+ (NSPoint) pointWithPolarCenter:(NSPoint)center radius:(float)r angle:(float)deg
{
    float rads = deg * M_PI / 180.0;
    return NSMakePoint(center.x + r * cos(rads), center.y + r * sin(rads));
}

+ (NSBezierPath*) circleSegmentWithCenter:(NSPoint)center startAngle:(float)a1 endAngle:(float)a2 smallRadius:(float)r1 bigRadius:(float)r2
{
    NSBezierPath *bp = [NSBezierPath bezierPath];
    [bp moveToPoint:[NSBezierPath pointWithPolarCenter:center radius:r1 angle:a1]];
    [bp appendBezierPathWithArcWithCenter:center radius:r1 startAngle:a1 endAngle:a2 clockwise:NO];
    [bp lineToPoint:[NSBezierPath pointWithPolarCenter:center radius:r2 angle:a2]];
    [bp appendBezierPathWithArcWithCenter:center radius:r2 startAngle:a2 endAngle:a1 clockwise:YES];
    [bp closePath];
    return bp;
}

+ (NSBezierPath *) bezierPathWithRoundedRect:(NSRect)aRect cornerRadius:(float)radius inCorners:(TACornerType)corners
{
	NSBezierPath* path = [self bezierPath];
	radius = MIN(radius, 0.5f * MIN(NSWidth(aRect), NSHeight(aRect)));
	NSRect rect = NSInsetRect(aRect, radius, radius);
	
	if (corners & TABottomLeftCorner) {
		[path appendBezierPathWithArcWithCenter:NSMakePoint(NSMinX(rect), NSMinY(rect)) radius:radius startAngle:180.0 endAngle:270.0];
	} else {
		NSPoint cornerPoint = NSMakePoint(NSMinX(aRect), NSMinY(aRect));
		[path appendBezierPathWithPoints:&cornerPoint count:1];
	}
	
	if (corners & TABottomRightCorner) {
		[path appendBezierPathWithArcWithCenter:NSMakePoint(NSMaxX(rect), NSMinY(rect)) radius:radius startAngle:270.0 endAngle:360.0];
	} else {
		NSPoint cornerPoint = NSMakePoint(NSMaxX(aRect), NSMinY(aRect));
		[path appendBezierPathWithPoints:&cornerPoint count:1];
	}

	if (corners & TATopRightCorner) {
		[path appendBezierPathWithArcWithCenter:NSMakePoint(NSMaxX(rect), NSMaxY(rect)) radius:radius startAngle: 0.0 endAngle:90.0];
	} else {
		NSPoint cornerPoint = NSMakePoint(NSMaxX(aRect), NSMaxY(aRect));
		[path appendBezierPathWithPoints:&cornerPoint count:1];
	}
	
	if (corners & TATopLeftCorner) {
		[path appendBezierPathWithArcWithCenter:NSMakePoint(NSMinX(rect), NSMaxY(rect)) radius:radius startAngle:90.0 endAngle:180.0];
	} else {
		NSPoint cornerPoint = NSMakePoint(NSMinX(aRect), NSMaxY(aRect));
		[path appendBezierPathWithPoints:&cornerPoint count:1];
	}
	
	[path closePath];
	return path;	
}

+ (NSBezierPath*)bezierPathWithRoundedRect:(NSRect)aRect cornerRadius:(float)radius
{
	return [NSBezierPath bezierPathWithRoundedRect:aRect cornerRadius:radius inCorners:TATopLeftCorner | TATopRightCorner | TABottomLeftCorner | TABottomRightCorner];
}

@end
