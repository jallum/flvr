#import "FLVRScrollView.h"

NSString* FLVRScrollViewChanged = \
    @"FLVRScrollViewChanged";

@implementation FLVRScrollView

- (void) reflectScrolledClipView:(NSClipView*)clipView
{
    [super reflectScrolledClipView:clipView];
    [[NSNotificationCenter defaultCenter] postNotificationName:FLVRScrollViewChanged object:self];
}

@end
