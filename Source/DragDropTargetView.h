#import <Cocoa/Cocoa.h>

@interface DragDropTargetView : NSView {
	int _phase;
	NSTimer* _timer;
	BOOL _highlighted;
}

@end
