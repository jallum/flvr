#import "Safari.h"

@interface ToolbarController (FLVR)

- (IBAction) FLVR_hook:(id)sender;
- (BrowserToolbarItem*) FLVR_toolbar:(BrowserToolbar*)toolbar itemForItemIdentifier:(NSString*)identifier willBeInsertedIntoToolbar:(BOOL)flag;
- (NSArray*) FLVR_toolbarAllowedItemIdentifiers:(BrowserToolbar*)toolbar;

@end
