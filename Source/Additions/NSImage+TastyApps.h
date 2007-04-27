#import <Cocoa/Cocoa.h>

@interface NSImage (TastyApps)

+ (NSImage*) imageNamed:(NSString*)name forClass:(Class)inClass;
+ (NSImage*) reflectedImage:(NSImage*)sourceImage amountReflected:(float)fraction;

@end
