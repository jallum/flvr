#import <Cocoa/Cocoa.h>

@class WebView;
@class FLVRNowPlayingView;

@interface TossToController : NSObject {
	IBOutlet NSPanel* _panel;
    IBOutlet WebView* _webView;
	IBOutlet FLVRNowPlayingView* _nowPlayingView;
	/**/
	NSStatusItem* _statusItem;
	BOOL _downloadImmediately;
}

@end

#define FLVRLocalizedString(x, y)   [[NSBundle bundleForClass:[TossToController class]] localizedStringForKey:x value:x table:nil]