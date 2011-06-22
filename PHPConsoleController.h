#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
#import <BWToolkitFramework/BWToolkitFramework.h>
#import "TaskWrapper.h"

@class NoodleLineNumberView;

@interface PHPConsoleController : NSObject <TaskWrapperController> {
    //IBOutlet id codeBox;
    IBOutlet id resultBox;
    IBOutlet id statusText;
    IBOutlet WebView* webKitView;
	IBOutlet BWAnchoredButton* execButton;
    IBOutlet NSButton* toggleButton;
    
    IBOutlet NSScrollView   *scrollView;
    IBOutlet NSTextView     *codeBox;
	NoodleLineNumberView	*lineNumberView;
    
    BOOL HTMLOutput; // Defaults to NO
    NSMutableString *html;
    NSString *binary_loc; // Defaults to /usr/bin/php
    
    NSInteger selectedThing;
    TaskWrapper *task;
}
- (IBAction)executeCode:(id)sender;
- (IBAction)HTMLOutputToggle:(id)sender;

// My special function
- (void)showPHPErrorExplanation;

// NSApplication delegate functions
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification;
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication;

// TaskWrapper delegate functions
- (void)appendOutput:(NSString *)output;
- (void)processStarted;
- (void)processFinished:(int)terminationStatus;

@end
