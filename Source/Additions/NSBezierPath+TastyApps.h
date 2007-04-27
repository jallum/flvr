#import <Cocoa/Cocoa.h>

typedef enum _TACornerTypes {
	TATopLeftCorner = 1,
	TABottomLeftCorner = 2,
	TATopRightCorner = 4,
	TABottomRightCorner = 8
} TACornerType;

@interface NSBezierPath (TastyApps)

+ (NSPoint) pointWithPolarCenter:(NSPoint)center radius:(float)r angle:(float)deg;
+ (NSBezierPath*) circleSegmentWithCenter:(NSPoint)center startAngle:(float)a1 endAngle:(float)a2 smallRadius:(float)r1 bigRadius:(float)r2;
+ (NSBezierPath *) bezierPathWithRoundedRect:(NSRect)aRect cornerRadius:(float)radius inCorners:(TACornerType)corners;
+ (NSBezierPath*)bezierPathWithRoundedRect:(NSRect)aRect cornerRadius:(float)radius;

@end