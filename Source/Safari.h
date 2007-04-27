#import <Cocoa/Cocoa.h>

@class ButtonWithMenu;
@class RolloverImageButton;
@class BrowserWebView;
@class EtchedStringView;
@class GoogleSuggestionController;
@class SplitView;
@class SlidingImageView;
@class WebDataSource;
@class URLCompletionController;
@class TabBarView;
@class FavoritesBar;
@class TextFieldEditor;
@class LocationFieldEditor;
@class LocationTextField;
@class SearchField;
@class ToolbarController;
@class TitleBarButton;


@interface BarBackground : NSView
{
}

+ (id)firstTopBorderLineColor;
+ (id)secondTopBorderLineColor;
+ (id)bottomBorderLineColor;
- (void)dealloc;
- (float)topBorderHeight;
- (void)drawRect:(struct _NSRect)fp8;
- (id)backgroundColor;
- (void)setBackgroundColor:(id)fp8;
- (void)setTintColor:(id)fp8;
- (id)tintColor;
- (BOOL)isOpaque;
- (BOOL)hasTopBorder;
- (void)setHasTopBorder:(BOOL)fp8;
- (BOOL)hasBottomBorder;
- (void)setHasBottomBorder:(BOOL)fp8;
- (BOOL)mouseDownCanMoveWindow;
- (void)setExternalNextKeyView:(id)fp8;
- (id)firstChildKeyView;
- (void)setFirstChildKeyView:(id)fp8;
- (id)lastChildKeyView;
- (void)setLastChildKeyView:(id)fp8;
- (void)setDefaultKeyLoop;
- (BOOL)acceptsFirstResponder;
- (BOOL)becomeFirstResponder;
- (void)setNextKeyView:(id)fp8;
- (id)accessibilityAttributeValue:(id)fp8;
- (BOOL)accessibilityIsIgnored;

@end

@interface WindowController : NSWindowController
{
}

- (void)dealloc;
- (void)_saveFrameIfAllowed;
- (void)windowDidMove:(id)fp8;
- (void)windowDidResize:(id)fp8;
- (void)_windowWillClose:(id)fp8;
- (BOOL)setMultiWindowFrameAutosaveName:(id)fp8;
- (id)multiWindowFrameAutosaveName;
- (void)_setFrameWithoutAutosaving:(struct _NSRect)fp8 programmatically:(BOOL)fp24;
- (void)setFrameWithoutAutosaving:(struct _NSRect)fp8;
- (void)setFrameProgrammatically:(struct _NSRect)fp8;
- (struct _NSRect)defaultFrame;
- (void)setFrameToDefault;
- (void)_windowDidLoad;
- (void)setFrameAutosaveEnabled:(BOOL)fp8;
- (BOOL)frameAutosaveEnabled;

@end

@interface FavoritesBarView : BarBackground
{
}

- (void)awakeFromNib;
- (void)setDelegate:(id)fp8;
- (unsigned int)builtInSubviewsCount;
- (void)reorderFavoriteButton:(id)fp8 fromMouseDownEvent:(id)fp12;
- (unsigned int)draggingEntered:(id)fp8;
- (unsigned int)draggingUpdated:(id)fp8;
- (void)draggingExited:(id)fp8;
- (void)draggingEnded:(id)fp8;
- (BOOL)performDragOperation:(id)fp8;
- (void)concludeDragOperation:(id)fp8;
- (void)pauseAnimation;
- (void)resumeAnimation;

@end

@interface Window : NSWindow
{
}

- (void)dealloc;
- (void)close;
- (void)becomeKeyWindow;
- (void)_setFrameAfterMove:(struct _NSRect)fp8;
- (id)findFrontmostOtherWindowOfWidth:(float)fp8;
- (struct _NSRect)adjustedFrameForCascade:(struct _NSRect)fp8 fromWindow:(id)fp24;
- (struct _NSPoint)cascadeTopLeftFromPoint:(struct _NSPoint)fp8;
- (BOOL)isResizable;
- (void)setResizable:(BOOL)fp8;
- (void)setFrame:(struct _NSRect)fp8 display:(BOOL)fp24;
- (BOOL)validateUserInterfaceItem:(id)fp8;

@end

@interface BrowserWindow : Window
{
}

+ (id)_lockImage;
- (void)_setTitleBarButton;
- (void)_positionSecurityButton;
- (void)_setUpSecurityButton;
- (void)awakeFromNib;
- (void)sendEvent:(id)fp8;
- (void)keyDown:(id)fp8;
- (void)updateCGSWindowTitle;
- (void)_commonAwake;
- (struct _NSRect)_adjustedFrameForSaving:(struct _NSRect)fp8;
- (struct _NSRect)adjustedFrameForCascade:(struct _NSRect)fp8 fromWindow:(id)fp24;
- (BOOL)performKeyEquivalent:(id)fp8;
- (void)logFirstPageLoadedAfterNextRedisplay;
- (void)logFirstPageLoaded;
- (void)display;
- (void)displayIfNeeded;
- (void)updateTitle;
- (void)close;
- (void)setTitle:(id)fp8;
- (id)title;
- (void)certificateSheetDidEnd:(id)fp8 returnCode:(int)fp12 contextInfo:(void *)fp16;
- (void)_securityButtonClicked:(id)fp8;
- (void)setIsShowingSecurityButton:(BOOL)fp8;
- (BOOL)isShowingSecurityButton;
- (void)dealloc;
- (void)setDelegate:(id)fp8;
- (void)setWindowController:(id)fp8;
- (void)flushWindow;
- (BOOL)ignoresOrderFront;
- (void)setIgnoresOrderFront:(BOOL)fp8;
- (void)orderFront:(id)fp8;
- (void)_handleFocusToolbarHotKey:(id)fp8;
- (BOOL)makeFirstResponder:(id)fp8;
- (id)accessibilityHitTest:(struct _NSPoint)fp8;
- (id)accessibilityAttributeValue:(id)fp8;

@end

@interface BrowserDocument : NSDocument
{
}

+ (BOOL)lastDocumentCouldShowInputFields;
- (id)initWithContentsOfRequest:(id)fp8 frameName:(id)fp12;
- (id)init;
- (id)initWithContentsOfURL:(id)fp8 ofType:(id)fp12;
- (void)dealloc;
- (void)close;
- (BOOL)shouldClose;
- (void)makeWindowControllers;
- (void)removeWindowController:(id)fp8;
- (BOOL)isDocumentEdited;
- (id)browserWindowController;
- (id)dataSourceToSave;
- (BOOL)canSaveAsWebArchive;
- (BOOL)isSavingWebArchive;
- (id)MIMETypeForSaving;
- (id)filenameForSaving;
- (BOOL)isSavingPlainText;
- (void)setFileWrapperToSave:(id)fp8 MIMEType:(id)fp12;
- (void)setDataSourceToSave:(id)fp8;
- (BOOL)saveToURL:(id)fp8 ofType:(id)fp12 forSaveOperation:(int)fp16 error:(id *)fp20;
- (void)saveDocument:(id)fp8;
- (void)saveDocumentAs:(id)fp8;
- (void)saveDocumentTo:(id)fp8;
- (void)document:(id)fp8 didSave:(BOOL)fp12 contextInfo:(void *)fp16;
- (id)allowedFileTypes;
- (void)_updateFileFormatInformationText;
- (void)fileFormatPopUpButtonUpdated:(id)fp8;
- (BOOL)prepareSavePanel:(id)fp8;
- (id)panel:(id)fp8 userEnteredFilename:(id)fp12 confirmed:(BOOL)fp16;
- (id)dataRepresentationOfType:(id)fp8;
- (BOOL)loadDataRepresentation:(id)fp8 ofType:(id)fp12;
- (id)untitledName;
- (id)displayName;
- (id)fileType;
- (void)_nameHasChanged;
- (id)mainWebFrameView;
- (void)showWindows;
- (unsigned int)validModesForFontPanel:(id)fp8;
- (void)changeFont:(id)fp8;
- (void)snapBackToSearchResults:(id)fp8;
- (BOOL)canShowInputFields;
- (BOOL)canUseAddressField;
- (BOOL)canUseSearchField;
- (void)searchWeb:(id)fp8;
- (void)setPageForSnapBackToCurrentPage:(id)fp8;
- (void)snapBackToPage:(id)fp8;
- (id)pageForSnapBack;
- (void)openLocation:(id)fp8;
- (void)goToRequest:(id)fp8 withTabLabel:(id)fp12;
- (id)evaluateJavaScript:(id)fp8;
- (void)goToURL:(id)fp8;
- (void)loadCloneOfView:(id)fp8;
- (id)currentURL;
- (BOOL)canGoHome;
- (void)goHome:(id)fp8;
- (BOOL)hasInitialContents;
- (void)displayInitialContents;
- (void)bugReportSheetDidEnd:(id)fp8 returnCode:(int)fp12 contextInfo:(void *)fp16;
- (void)reportBugToApple:(id)fp8;
- (void)goToItemInBackOrForwardMenu:(id)fp8;
- (void)_addItem:(id)fp8 toMenu:(id)fp12;
- (id)backListMenuForButton:(id)fp8;
- (id)forwardListMenuForButton:(id)fp8;
- (void)reload:(id)fp8;
- (void)setShouldStartEmpty;
- (void)makeTextLarger:(id)fp8;
- (void)makeTextSmaller:(id)fp8;
- (void)stopLoading:(id)fp8;
- (BOOL)isLoading;
- (id)printInfo;
- (void)setPrintInfo:(id)fp8;
- (void)printWebFrameView:(id)fp8 showingPrintPanel:(BOOL)fp12 useSheet:(BOOL)fp16;
- (id)_selectedFrameView;
- (id)_printingMailingFrameView;
- (void)printShowingPrintPanel:(BOOL)fp8;
- (void)_updateTitleOfPrintMenuItem:(id)fp8;
- (BOOL)canPrint;
- (BOOL)canAddBookmark;
- (id)syndicationURLWithFilter;
- (id)createBookmarkRespectingProvisionalPage:(BOOL)fp8;
- (void)proposeBookmarkRespectingProvisionalPage:(BOOL)fp8;
- (void)proposeBookmarkForProvisionalOrCurrentPage;
- (void)addBookmark:(id)fp8;
- (void)addBookmarkToMenu:(id)fp8;
- (void)proposeBookmarkForCurrentURL;
- (void)clearAllStatus;
- (BOOL)_isDocumentHTML;
- (BOOL)_isDisplayingCompletePage;
- (BOOL)_isDisplayingLoadErrorPage;
- (BOOL)canViewSource;
- (BOOL)canMailPage;
- (BOOL)canMailPageAddress;
- (BOOL)canOpenInDashboard;
- (BOOL)canSave;
- (BOOL)validateUserInterfaceItem:(id)fp8;
- (void)viewSource:(id)fp8;
- (id)currentWebView;
- (void)tryMultipleURLs:(id)fp8;
- (BOOL)shouldOpenWindowBehindFrontmost;
- (void)setShouldOpenWindowBehindFrontmost:(BOOL)fp8;
- (id)_mailApplicationPath;
- (BOOL)_mailApplicationAtPath:(id)fp8 supportsKey:(id)fp12;
- (BOOL)_sendMessageEventToMailPath:(id)fp8 eventID:(unsigned long)fp12 directObject:(id)fp16 title:(id)fp20;
- (void)mailPage:(id)fp8;
- (void)_reportLaunchFailureForMailApplicationAtPath:(id)fp8;
- (void)mailPageAddress:(id)fp8;
- (id)webWidgetURLWithParameters:(id)fp8;
- (void)openInDashboard:(id)fp8;
- (id)URLString;
- (void)setURLString:(id)fp8;
- (id)source;
- (id)text;
- (void)clearPageCache;
- (id)pageName;
- (id)createWebViewWithFrameName:(id)fp8;
- (id)createWebView;
- (void)removeWebView:(id)fp8;
- (void)setCurrentWebView:(id)fp8;

@end

@protocol ProvidesSearchTarget
- (id)targetForSearch;
@end

@protocol ReopensAtLaunch
+ (void)reopen;
@end

@interface BrowserWindowController : WindowController <ProvidesSearchTarget, ReopensAtLaunch>
{
}

//	10.5
- (id)document;


//	10.4
+ (int)windowPolicyFromEventModifierFlags:(unsigned int)fp8 requireCommandKey:(BOOL)fp12;
+ (int)windowPolicyFromEventModifierFlags:(unsigned int)fp8;
+ (int)windowPolicyFromCurrentEventRequireCommandKey:(BOOL)fp8;
+ (int)windowPolicyFromCurrentEvent;
+ (int)windowPolicyFromCurrentEventRespectingKeyEquivalents:(BOOL)fp8;
+ (void)reopen;
- (id)browserDocument;
- (id)currentWebView;
- (id)currentBookmarksViewController;
- (id)windowNibName;
- (id)locationField;
- (id)searchField;
- (void)_makeFirstResponder:(id)fp8;
- (void)_makeLocationFieldFirstResponder;
- (void)_makeSearchFieldFirstResponder;
- (BOOL)_searchFieldIsFirstResponder;
- (void)updateSearchSnapBackButton;
- (void)updateSnapBackButtons;
- (void)webViewPageForSnapBackHasChanged:(id)fp8;
- (void)setUpSearchField;
- (BOOL)locationBarIsShowing;
- (void)setUpLocationBar;
- (BOOL)isShowingBookmarks;
- (BOOL)allowBookmarksChanges;
- (BOOL)firstResponderIsDescendantOf:(id)fp8;
- (id)selectedTab;
- (id)mainWebFrameView;
- (BOOL)isShowingBar:(id)fp8;
- (void)updateKeyboardLoop;
- (void)collectViewFramesForResizing;
- (void)getTabLabel:(id *)fp8 andToolTip:(id *)fp12 forWebView:(id)fp16;
- (id)tabLabelForWebView:(id)fp8;
- (void)updateLabelForTab:(id)fp8 evenIfTabBarHidden:(BOOL)fp12;
- (void)updateLabelForTab:(id)fp8;
- (id)setUpTabForWebView:(id)fp8 addToRightSide:(BOOL)fp12;
- (id)setUpTabForWebView:(id)fp8;
- (BOOL)alwaysShowTabBar;
- (struct _NSRect)defaultFrame;
- (BOOL)searchFieldShouldShowGoogleSuggestions;
- (id)completionController;
- (id)searchSuggestionController;
- (void)_preloadImages;
- (void)windowWillLoad;
- (void)windowDidLoad;
- (BOOL)_windowIsFullHeight;
- (struct _NSRect)adjustedFrameForSaving:(struct _NSRect)fp8;
- (struct _NSRect)adjustedFrameForCascade:(struct _NSRect)fp8 fromWindow:(id)fp24;
- (struct _NSSize)windowWillResize:(id)fp8 toSize:(struct _NSSize)fp12;
- (void)windowDidResize:(id)fp8;
- (void)setDocumentEdited:(BOOL)fp8;
- (void)dealloc;
- (void)setDocument:(id)fp8;
- (void)stopLoading:(id)fp8;
- (void)cancel:(id)fp8;
- (BOOL)windowWillHandleKeyEvent:(id)fp8;
- (id)_computePriorFirstResponder;
- (void)locationTextFieldURLDropped:(id)fp8;
- (id)windowWillReturnFieldEditor:(id)fp8 toObject:(id)fp12;
- (struct _NSSize)bestWindowSizeForBookmarksOutline;
- (struct _NSSize)bestWindowSizeForCurrentPageWithDefaultSize:(struct _NSSize)fp8;
- (struct _NSRect)windowWillUseStandardFrame:(id)fp8 defaultFrame:(struct _NSRect)fp12;
- (id)windowTitleBarURL;
- (id)windowURL;
- (id)locationFieldURL;
- (void)windowShouldGoToURL:(id)fp8;
- (BOOL)windowShouldClose:(id)fp8;
- (void)toggleLocationBarWithoutSavingConfiguration;
- (void)showLocationBarTemporarilyIfHidden;
- (void)makeLocationBarPermanentIfTemporary;
- (void)hideLocationBarIfTemporary;
- (void)selectSearchField:(id)fp8;
- (BOOL)canShowInputFields;
- (BOOL)searchField:(id)fp8 shouldRememberSearchString:(id)fp12;
- (void)setPendingSearchURL:(id)fp8;
- (void)noResponderFor:(SEL)fp8;
- (void)performQuickSearch:(id)fp8;
- (void)webFrameLoadStarted:(id)fp8;
- (void)updateLocationFieldTextNow;
- (void)updateLocationFieldTextSoon;
- (void)updateSecureIcon;
- (void)updateRSSButton;
- (id)createIncomingImageForRSSTransition;
- (void)removeRSSTransitionImageViewAndDisplay:(BOOL)fp8;
- (void)cancelRSSAnimationAfterSpecificInterval;
- (void)cleanUpRSSAnimationAndDisplay:(BOOL)fp8;
- (void)advanceRSSAnimation;
- (void)startRSSAnimationWithSlowMotion:(BOOL)fp8;
- (void)installRSSTransitionImageView;
- (void)goToCounterpartURLForRSSWithSlowMotion:(BOOL)fp8;
- (void)webFrameLoadCommitted:(id)fp8;
- (void)startRSSAnimation;
- (void)startRSSAnimationForFrame:(id)fp8 error:(id)fp12;
- (void)startRSSAnimationAfterSpecificInterval;
- (void)webFrameLoadDidFirstLayout:(id)fp8;
- (void)webFrameLoadFinished:(id)fp8 withError:(id)fp12;
- (void)webFrame:(id)fp8 willPerformClientRedirectToURL:(id)fp12;
- (BOOL)shouldMakeFirstResponder:(id)fp8;
- (void)tryToAutofillPasswords:(id)fp8;
- (id)locationFieldText;
- (void)setLocationFieldText:(id)fp8;
- (void)selectLocationField:(id)fp8;
- (void)tryMultipleURLs:(id)fp8 windowPolicy:(int)fp12;
- (void)goToToolbarLocationWithWindowPolicy:(int)fp8;
- (void)goToToolbarLocation:(id)fp8;
- (BOOL)locationFieldIsEmpty;
- (BOOL)searchFieldIsEmpty;
- (BOOL)locationFieldTextIsCurrentURL;
- (BOOL)locationFieldTextIsLocationFieldURL;
- (BOOL)updateStopAndReloadButtonNow;
- (void)updateStopAndReloadButtonSoon;
- (void)updateToggleBookmarksButton;
- (void)setLoading:(BOOL)fp8;
- (BOOL)isAvailableForForcedLocationUsingWindowPolicy:(int)fp8;
- (void)reloadObeyingLocationField:(id)fp8;
- (void)stopOrReload:(id)fp8;
- (void)updateWindowTitleNow;
- (void)updateWindowTitleSoon;
- (void)windowTitleNeedsUpdate;
- (void)toggleShowBookmarks:(id)fp8;
- (void)newBookmarkFolder:(id)fp8;
- (void)editAddressOfFavorite:(id)fp8;
- (void)editContentsOfFavorite:(id)fp8;
- (void)editTitleOfFavorite:(id)fp8;
- (void)revealFavorite:(id)fp8;
- (void)deleteBookmark:(id)fp8;
- (void)editTitleOfBookmarksCollection:(id)fp8;
- (void)setUpFavoritesBar;
- (void)toggleBar:(id)fp8 withAnimation:(BOOL)fp12 isShowing:(char *)fp16;
- (void)toggleFavoritesBarWithAnimation:(BOOL)fp8;
- (void)toggleFavoritesBar:(id)fp8;
- (void)toggleToolbarIgnoringCurrentEvent:(id)fp8;
- (void)toggleLocationBar:(id)fp8;
- (void)setToolbarsVisible:(BOOL)fp8;
- (BOOL)anyToolbarsVisible;
- (void)toggleTabBarWithAnimation:(BOOL)fp8;
- (void)setUpTabBar;
- (void)showTab:(id)fp8;
- (void)showTabAtIndex:(int)fp8;
- (BOOL)moreThanOneTabShowing;
- (void)updateCloseKeyEquivalents;
- (id)createTabWithFrameName:(id)fp8 andShow:(BOOL)fp12 addToRightSide:(BOOL)fp16;
- (id)createTabWithFrameName:(id)fp8;
- (id)createInactiveTabWithFrameName:(id)fp8;
- (id)createTab;
- (id)createInactiveTab;
- (void)newTab:(id)fp8;
- (void)closeTab:(id)fp8;
- (void)closeCurrentTab:(id)fp8;
- (void)closeOtherTabs:(id)fp8;
- (void)closeInactiveTabs:(id)fp8;
- (void)reloadTabsMatchingURLs:(id)fp8;
- (void)tabBarView:(id)fp8 didClickTabViewItem:(id)fp12;
- (void)tabBarView:(id)fp8 didClickCloseButtonForTabViewItem:(id)fp12 mouseDownModifierFlags:(unsigned int)fp16;
- (void)willSelectTabViewItem;
- (void)didSelectTabViewItem;
- (void)tabView:(id)fp8 willSelectTabViewItem:(id)fp12;
- (void)tabView:(id)fp8 didSelectTabViewItem:(id)fp12;
- (void)selectNextTab:(id)fp8;
- (void)selectPreviousTab:(id)fp8;
- (id)findTabForWebView:(id)fp8;
- (void)selectTab:(id)fp8;
- (void)closeTabOrWindow:(id)fp8;
- (void)webViewNameHasChanged:(id)fp8;
- (void)webViewLocationFieldURLHasChanged:(id)fp8;
- (void)webViewLocationFieldIconHasChanged:(id)fp8;
- (id)tabBarView:(id)fp8 menuForEvent:(id)fp12;
- (id)tabBarView:(id)fp8 menuForButtonForTabViewItem:(id)fp12 event:(id)fp16;
- (id)tabBarView:(id)fp8 menuForClippedTabViewItems:(id)fp12;
- (void)selectClippedTabViewItem:(id)fp8;
- (void)closeTabFromMenu:(id)fp8;
- (void)closeOtherTabsFromMenu:(id)fp8;
- (void)reloadTab:(id)fp8;
- (void)reloadTabFromMenu:(id)fp8;
- (void)reloadAllTabs:(id)fp8;
- (BOOL)shouldShowTabBar;
- (void)updateTabBarVisibility;
- (void)reloadParentallyRestrictedFrames;
- (void)defaultsDidChange;
- (void)windowDidBecomeKey:(id)fp8;
- (void)fixFocusRingAroundLocationField;
- (void)windowDidResignKey:(id)fp8;
- (BOOL)shouldCloseDocument;
- (id)replaceTabSwitcher:(id)fp8;
- (void)releaseTabSwitcher:(id)fp8;
- (void)releaseTabSwitchersForBackForward;
- (void)replaceTabURLs:(id)fp8 usingTabLabelsFromBookmarks:(id)fp12;
- (void)updateTabLabelForWebView:(id)fp8;
- (void)webViewSheetRequestStatusHasChanged:(id)fp8;
- (void)webViewLoadingStatusHasChanged:(id)fp8;
- (id)orderedTabs;
- (void)tabBarView:(id)fp8 performDragOperationForTabViewItem:(id)fp12 URL:(id)fp16;
- (void)tabBarView:(id)fp8 performDragOperationForURL:(id)fp12 droppedOnRightSide:(BOOL)fp16;
- (void)setUpStatusBar;
- (void)toggleStatusBarWithAnimation:(BOOL)fp8;
- (void)toggleStatusBar:(id)fp8;
- (id)_defaultStatus;
- (void)clearStatus;
- (void)setStatusMessageNow;
- (void)setStatusMessage:(id)fp8 ellipsize:(BOOL)fp12;
- (void)updateStatusMessage;
- (void)webViewStatusMessageHasChanged:(id)fp8;
- (BOOL)isStatusBarVisible;
- (void)setStatusBarVisible:(BOOL)fp8;
- (BOOL)acceptsGenericIcon;
- (void)setAcceptsGenericIcon:(BOOL)fp8;
- (void)updateLocationFieldIconNow;
- (void)updateLocationFieldIconSoon;
- (void)controlTextDidChange:(id)fp8;
- (void)controlTextDidEndEditing:(id)fp8;
- (BOOL)control:(id)fp8 textView:(id)fp12 doCommandBySelector:(SEL)fp16;
- (void)updatePopUpCheckmark:(id)fp8;
- (float)splitView:(id)fp8 constrainMaxCoordinate:(float)fp12 ofSubviewAt:(int)fp16;
- (float)splitView:(id)fp8 constrainMinCoordinate:(float)fp12 ofSubviewAt:(int)fp16;
- (float)rememberCurrentInputFieldWidthRatioForSplitView:(id)fp8;
- (void)splitViewDidResizeSubviews:(id)fp8;
- (void)splitView:(id)fp8 resizeSubviewsWithOldSize:(struct _NSSize)fp12;
- (id)targetForSearch;
- (BOOL)goToBookmarks;
- (void)goBack:(id)fp8;
- (void)goForward:(id)fp8;
- (BOOL)canGoBack;
- (BOOL)canGoForward;
- (id)backListMenuForButton:(id)fp8;
- (id)forwardListMenuForButton:(id)fp8;
- (BOOL)canOpenInDashboard;
- (BOOL)canAddBookmark;
- (BOOL)canGoHome;
- (BOOL)canAutoFill;
- (BOOL)canPrintFromToolbar;
- (void)goHome:(id)fp8;
- (void)openInDashboard:(id)fp8;
- (void)addBookmark:(id)fp8;
- (BOOL)canToggleShowSearchField;
- (void)toggleShowGoogleSearch:(id)fp8;
- (BOOL)canReloadObeyingLocationField;
- (BOOL)canReloadTab:(id)fp8;
- (BOOL)canReloadAllTabs;
- (BOOL)validateUserInterfaceItem:(id)fp8;
- (BOOL)validateMenuItem:(id)fp8;
- (void)changeTextEncoding:(id)fp8;
- (void)setSearchFieldText:(id)fp8;
- (id)searchFieldText;
- (void)searchForString:(id)fp8;
- (void)chooseSearchString:(id)fp8;
- (void)recentSearchesCleared:(id)fp8;
- (void)textFieldWithControlsPerformRightButtonAction:(id)fp8;
- (void)textFieldWithControlsPerformRightButton2Action:(id)fp8;
- (void)textFieldWithControls:(id)fp8 mouseUpInRightButton:(id)fp12;
- (void)textFieldWithControls:(id)fp8 mouseUpInRightButton2:(id)fp12;
- (id)bookmarkTitleForLocationField:(id)fp8;
- (void)setProgressBarValue:(double)fp8;
- (void)updateProgressBarNow;
- (void)performCoalescedUpdates;
- (void)performCoalescedUpdateSoon:(int)fp8;
- (void)cancelCoalescedUpdate:(int)fp8;
- (void)updateProgressBarSoon;
- (void)updateProgressBar:(BOOL)fp8;
- (void)showCompleteProgressBarNow;
- (void)showCompleteProgressBarSoon;
- (void)clearProgressBar;
- (void)webViewProgressFinished:(id)fp8;
- (void)tellUserThatAppIsHosed;
- (void)showWindow:(id)fp8;
- (void)makeTextLarger:(id)fp8;
- (void)makeTextSmaller:(id)fp8;
- (void)reportBugToApple:(id)fp8;
- (void)printFromToolbar:(id)fp8;
- (void)autoFill:(id)fp8;

@end

@interface BrowserToolbar : NSToolbar
{
}

- (BOOL)_allowsDisplayMode:(int)fp8;
- (BOOL)_allowsSizeMode:(int)fp8;
- (id)_customMetrics;
- (BOOL)_drawsBackground;

@end

@interface BrowserToolbarItem : NSToolbarItem
{
}

- (unsigned int)handledMouseDownModifiersMask;
- (void)setHandledMouseDownModifiersMask:(unsigned int)fp8;
- (BOOL)_allowToolbarToStealEvent:(id)fp8;
- (id)initWithItemIdentifier:(id)fp8 target:(id)fp12 view:(id)fp16;
- (id)initWithItemIdentifier:(id)fp8 target:(id)fp12 boxOfButtons:(id)fp16 label:(id)fp20;
- (id)initWithItemIdentifier:(id)fp8 target:(id)fp12 button:(id)fp16;
- (void)validate;

@end

@interface ToolbarController : NSObject
{
}

- (void)layOutInputFields;
- (void)updateToolbarSettings;
- (void)appendItemWithIdentifier:(id)fp8;
- (void)appendItemWithIdentifier:(id)fp8 accordingToDefault:(id)fp12;
- (void)convertOldDefaults;
- (void)insertOpenInDashboardItem;
- (void)insertMandatoryItems;
- (id)initWithBrowserWindowController:(id)fp8;
- (void)dealloc;
- (id)toolbar:(id)fp8 itemForItemIdentifier:(id)fp12 willBeInsertedIntoToolbar:(BOOL)fp16;
- (id)toolbarDefaultItemIdentifiers:(id)fp8;
- (id)toolbarAllowedItemIdentifiers:(id)fp8;
- (id)backButton;
- (id)forwardButton;
- (id)addBookmarkButton;
- (id)autoFillButton;
- (id)textBiggerButton;
- (id)textSmallerButton;
- (id)homeButton;
- (id)printButton;
- (id)stopOrReloadButton;
- (id)locationField;
- (id)searchField;
- (BOOL)shouldShowGoogleSearch;
- (void)setShouldShowGoogleSearch:(BOOL)fp8;
- (BOOL)canShowInputFields;
- (void)defaultsDidChange;

@end

@interface ButtonPlus : NSButton
{
}

- (void)mouseDown:(id)fp8;
- (unsigned int)lastMouseDownModifierFlags;
- (void)rightMouseDown:(id)fp8;

@end

@interface RolloverTrackingButton : ButtonPlus
{
}

- (void)initTrackingRect;
- (id)initWithFrame:(struct _NSRect)fp8;
- (void)setFrameOrigin:(struct _NSPoint)fp8;
- (void)setFrameSize:(struct _NSSize)fp8;
- (void)setFrameRotation:(float)fp8;
- (void)setBoundsOrigin:(struct _NSPoint)fp8;
- (void)setBoundsSize:(struct _NSSize)fp8;
- (void)setBoundsRotation:(float)fp8;
- (void)awakeFromNib;
- (void)dealloc;
- (BOOL)mouseIsOver;
- (void)mouseEnteredOrExited:(BOOL)fp8;
- (void)setRedrawOnMouseEnteredAndExited:(BOOL)fp8;
- (BOOL)redrawOnMouseEnteredAndExited;
- (void)updateMouseIsOver:(int)fp8;
- (void)removeTrackingRect;
- (void)updateTrackingRect;
- (void)_updateTrackingRectSoon;
- (void)viewWillMoveToWindow:(id)fp8;
- (void)viewDidMoveToWindow;
- (void)mouseEntered:(id)fp8;
- (void)mouseExited:(id)fp8;
- (void)rightMouseDown:(id)fp8;
- (void)setDelegate:(id)fp8;
- (id)delegate;

@end

@interface RolloverImageButton : RolloverTrackingButton
{
}

- (void)_setAttributes;
- (id)initWithFrame:(struct _NSRect)fp8;
- (void)awakeFromNib;
- (void)dealloc;
- (void)setRolloverImage:(id)fp8;
- (id)rolloverImage;
- (void)drawRect:(struct _NSRect)fp8;

@end


