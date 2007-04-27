#import "FLVRPulseButton.h"

@implementation FLVRPulseButton

- (void) dealloc
{
    [self stopPulsing:nil];
    [images release];
    [originalImage release];
    [super dealloc];
}

- (IBAction) startPulsing:(id)sender
{
    if (!timer) {
        if (!images) {
            images = [[NSMutableArray arrayWithCapacity:10] retain];
            NSImage* normal = originalImage = [[self image] retain];
            NSImage* pressed = [self alternateImage];
            for (int i = 0; i < 10; i++) {
                NSImage* image = [[NSImage alloc] initWithSize:[normal size]];

                [image lockFocus];
                [normal compositeToPoint:NSMakePoint(0,0) operation:NSCompositeSourceOver fraction:1.0];
                [pressed compositeToPoint:NSMakePoint(0,0) operation:NSCompositeSourceOver fraction:0.01 + (i * 0.7) / 10];
                [image unlockFocus];

                [images addObject:image];
                [image release];
            }
        }
        direction = 0;
        index = 0;
        timer = [[NSTimer scheduledTimerWithTimeInterval:(1.0 / 10) target:self selector:@selector(_pulse:) userInfo:nil repeats:YES] retain];
    }
}

- (void) mouseDown:(NSEvent*)event
{
    [super mouseDown:event];
    [self stopPulsing:nil];
}

- (IBAction) stopPulsing:(id)sender
{
    if (timer) {
        [timer invalidate];
        [timer release];
        timer = nil;
    }
    if (originalImage) {
        [self setImage:originalImage];
    }
    [self setNeedsDisplay];
}

- (void) _pulse:(NSTimer*)theTimer
{
    [self setImage:[images objectAtIndex:index]];
    if (direction) {
        index++;
        if (index == 10) {
            direction = !direction;
            index--;
        }
    } else {
        index--;
        if (index == -1) {
            direction = !direction;
            index++;
        }
    }
}

@end
