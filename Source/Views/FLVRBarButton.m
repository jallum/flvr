#import "FLVRBarButton.h"
#import "CTGradient.h"

@interface FLVRBarButton (Private)
- (NSImage*) _buttonBackgroundWithColor:(NSColor*)color size:(NSSize)size;
- (void) _createImages;
- (void) _resetBounds:(NSNotification*)notification;
- (void) _setForActive:(NSNotification*)notification;
- (void) _setForInactive:(NSNotification*)notification;
@end

@implementation FLVRBarButton

//height of button should be 17.0
- (id) initWithCoder:(NSCoder*)coder
{
    if ((self = [super initWithCoder:coder])) {
        fTrackingTag = 0;
        
        [self _createImages];
        
        [self setImage:_buttonNormal];
        [self setAlternateImage:_buttonPressed];
        
        NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
        [nc addObserver:self selector:@selector(_setForActive:) name:NSWindowDidBecomeKeyNotification object:nil];
        [nc addObserver:self selector:@selector(_setForInactive:) name:NSWindowDidResignKeyNotification object:nil];
        [nc addObserver:self selector:@selector(_resetBounds:) name:NSViewFrameDidChangeNotification object:nil];
    }
    return self;
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [_buttonNormal release];
    [_buttonOver release];
    [_buttonPressed release];
    [_buttonSelected release];
    [_buttonSelectedDim release];
    
    [super dealloc];
}

- (void) mouseEntered:(NSEvent*)event
{
    if (!_selected) {
        [self setImage:_buttonOver];
    }
    [super mouseEntered:event];
}

- (void) mouseExited:(NSEvent*)event
{
    if (!_selected) {
        [self setImage:_buttonNormal];
    }
    [super mouseExited:event];
}

- (void) setSelected:(BOOL)selected
{
    _selected = selected;
    [self setImage:_selected ? _buttonSelected : _buttonNormal];
}

- (NSImage*) _buttonBackgroundWithColor:(NSColor*)color size:(NSSize)size
{
    NSImage* button = [[NSImage alloc] initWithSize:size];
    
    NSRect r = NSMakeRect(0, 0, size.width, size.height);
    const float minX = NSMinX(r);
    const float minY = NSMinY(r);
    const float maxX = NSMaxX(r);
    const float maxY = NSMaxY(r);
    const float midX = NSMidX(r); 
    const float midY = NSMidY(r);
    const float radius = 10;
    NSBezierPath* bgPath = [NSBezierPath bezierPath];

    [button lockFocus];

    [bgPath moveToPoint:NSMakePoint(midX, minY)];

    //    bottom, right, top, left
    [bgPath appendBezierPathWithArcFromPoint:NSMakePoint(maxX, minY) toPoint:NSMakePoint(maxX, midY) radius:radius];
    [bgPath appendBezierPathWithArcFromPoint:NSMakePoint(maxX, maxY) toPoint:NSMakePoint(midX, maxY) radius:radius];
    [bgPath appendBezierPathWithArcFromPoint:NSMakePoint(minX, maxY) toPoint:NSMakePoint(minX, midY) radius:radius];
    [bgPath appendBezierPathWithArcFromPoint:NSMakePoint(minX, minY) toPoint:NSMakePoint(midX, minY) radius:radius];

    [bgPath closePath];
    
    [bgPath setClip];
    CTGradient* gradient = [CTGradient gradientWithBeginningColor:color endingColor:[color blendedColorWithFraction:0.3 ofColor:[NSColor whiteColor]]];
    [gradient fillRect:r angle:90];
    
    [button unlockFocus];
    return button;
}

//call only once
- (void) _createImages
{
    [[NSGraphicsContext currentContext] saveGraphicsState];

    NSSize buttonSize = [self frame].size;
    _buttonNormal = [self _buttonBackgroundWithColor:[NSColor colorWithCalibratedRed:0.0 green:0.3 blue:0.6 alpha:8.0] size:buttonSize];
    _buttonNormalDim = [_buttonNormal copy];
    _buttonOver = [self _buttonBackgroundWithColor:[NSColor colorWithCalibratedRed:0.0 green:0.3 blue:0.8 alpha:8.0] size:buttonSize];
    _buttonPressed = [self _buttonBackgroundWithColor:[NSColor colorWithCalibratedRed:0.0 green:0.3 blue:0.9 alpha:8.0] size:buttonSize];
    _buttonSelected = [self _buttonBackgroundWithColor:[NSColor colorWithCalibratedRed:0.0 green:0.3 blue:1.0 alpha:8.0] size:buttonSize];
    _buttonSelectedDim = [_buttonSelected copy];

    //create button text
    NSString* text = [self title];

    NSFont* boldFont = [[NSFontManager sharedFontManager] convertFont:[NSFont fontWithName:@"Lucida Grande" size:12.0] toHaveTrait:NSBoldFontMask];
    
    NSSize shadowOffset = NSMakeSize(0.0, -1.0);
    
    NSShadow* shadowNormal = [NSShadow alloc]; 
    [shadowNormal setShadowOffset:shadowOffset]; 
    [shadowNormal setShadowBlurRadius:1.0]; 
    [shadowNormal setShadowColor:[NSColor colorWithDeviceWhite:0.0 alpha:0.4]]; 

    NSShadow* shadowNormalDim = [NSShadow alloc]; 
    [shadowNormalDim setShadowOffset:shadowOffset]; 
    [shadowNormalDim setShadowBlurRadius:1.0]; 
    [shadowNormalDim setShadowColor:[NSColor colorWithDeviceWhite:0.0 alpha:0.4]]; 

    NSShadow* shadowSelected = [NSShadow alloc]; 
    [shadowSelected setShadowOffset:shadowOffset]; 
    [shadowSelected setShadowBlurRadius:1.0]; 
    [shadowSelected setShadowColor:[NSColor colorWithDeviceWhite:0.0 alpha:0.4]]; 
    
    NSDictionary* normalAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:
        [NSColor colorWithCalibratedRed:0.9 green:0.9 blue:0.9 alpha:1.0], NSForegroundColorAttributeName,
        boldFont, NSFontAttributeName,
        shadowNormal, NSShadowAttributeName, 
        nil
    ];
    NSDictionary* normalDimAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:
        [NSColor disabledControlTextColor], NSForegroundColorAttributeName,
        boldFont, NSFontAttributeName,
        shadowNormalDim, NSShadowAttributeName, 
        nil
    ];
    NSDictionary* selectedAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:
        [NSColor whiteColor], NSForegroundColorAttributeName,
        boldFont, NSFontAttributeName,
        shadowSelected, NSShadowAttributeName, 
        nil
    ];
    NSDictionary* selectedDimAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:
        [NSColor colorWithCalibratedRed:0.9 green:0.9 blue:0.9 alpha:1.0], NSForegroundColorAttributeName,
        boldFont, NSFontAttributeName,
        shadowSelected, NSShadowAttributeName, 
        nil
    ];
    
    NSSize textSizeNormal = [text sizeWithAttributes:normalAttributes];
     
    NSRect textRect = NSMakeRect(
        (buttonSize.width - textSizeNormal.width)* 0.5, 
        (buttonSize.height - textSizeNormal.height)* 0.5 + 1/*.5*/, 
        textSizeNormal.width, 
        textSizeNormal.height
    );
    
    [shadowNormal release];
    [shadowNormalDim release];
    [shadowSelected release];
    
    //normal button
    [_buttonNormal lockFocus];
    [text drawInRect:textRect withAttributes:normalAttributes];
    [_buttonNormal unlockFocus];
    
    //normal and dim button
    [_buttonNormalDim lockFocus];
    [text drawInRect:textRect withAttributes:normalDimAttributes];
    [_buttonNormalDim unlockFocus];
    
    //rolled over button
    [_buttonOver lockFocus];
    [text drawInRect:textRect withAttributes:selectedAttributes];
    [_buttonOver unlockFocus];
    
    //pressed button
    [_buttonPressed lockFocus];
    [text drawInRect:textRect withAttributes:selectedAttributes];
    [_buttonPressed unlockFocus];
    
    //selected button
    [_buttonSelected lockFocus];
    [text drawInRect:textRect withAttributes:selectedAttributes];
    [_buttonSelected unlockFocus];
    
    //selected and dim button
    [_buttonSelectedDim lockFocus];
    [text drawInRect:textRect withAttributes:selectedDimAttributes];
    [_buttonSelectedDim unlockFocus];
    
    [normalAttributes release];
    [normalDimAttributes release];
    [selectedAttributes release];
    [selectedDimAttributes release];

    [[NSGraphicsContext currentContext] restoreGraphicsState];
}

- (void) _resetBounds:(NSNotification*)notification
{
    if (fTrackingTag) {
        [self removeTrackingRect:fTrackingTag];
    }
    fTrackingTag = [self addTrackingRect:[self bounds] owner:self userData:nil assumeInside:NO];
}

- (void) _setForActive:(NSNotification*)notification
{
    if ([notification object] != [self window]) {
        return;
    }

    if ([self image] == _buttonSelectedDim) {
        [self setImage:_buttonSelected];
    } else if ([self image] == _buttonNormalDim) {
        [self setImage:_buttonNormal];
    }

    [self _resetBounds:nil];
}

- (void) _setForInactive:(NSNotification*)notification
{
    if ([notification object] != [self window]) {
        return;
    }

    [self setImage:[self image] == _buttonSelected ? _buttonSelectedDim :_buttonNormalDim];

    if (fTrackingTag) {
        [self removeTrackingRect:fTrackingTag];
    }
}

@end
