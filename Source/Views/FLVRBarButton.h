#import <Cocoa/Cocoa.h>

@interface FLVRBarButton : NSButton {
  NSImage* _buttonNormal;
  NSImage* _buttonNormalDim;
  NSImage* _buttonOver;
  NSImage* _buttonPressed;
  NSImage* _buttonSelected;
  NSImage* _buttonSelectedDim;
  NSTrackingRectTag fTrackingTag;
  BOOL _selected;
}

- (void) setSelected:(BOOL)selected;

@end
