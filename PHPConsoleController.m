#import "PHPConsoleController.h"
#import "NoodleLineNumberView.h"
#import "NoodleLineNumberMarker.h"
#import "MarkerLineNumberView.h"

// Init controller
@implementation PHPConsoleController
- (IBAction)executeCode:(id)sender {
    if ([[sender title] isEqualToString:@"Execute"]) {
        NSTask *determinier = [[NSTask alloc] init];
        [determinier setLaunchPath:[[NSUserDefaults standardUserDefaults] stringForKey:@"php_binary"]];
        NSPipe *output = [[NSPipe alloc] init];
        [determinier setStandardOutput:output];
        NSArray *terminateOnErrors = [[NSUserDefaults standardUserDefaults] arrayForKey:@"terminating_errors"];
        [determinier setArguments:[NSArray arrayWithObjects:@"-r",[NSString stringWithFormat:@"echo %@;", [terminateOnErrors componentsJoinedByString:@"^"]], nil]];
        [determinier launch];
        [determinier waitUntilExit];
        NSString *theResult = [[NSString alloc] initWithData:[[output fileHandleForReading] readDataToEndOfFile] encoding:NSASCIIStringEncoding];
        
        //NSLog(theResult);
        NSArray *args = [NSArray arrayWithObjects:[[NSUserDefaults standardUserDefaults] stringForKey:@"php_binary"], 
                                                    @"-d", [NSString stringWithFormat:@"error_reporting=%@", theResult], nil];
        task = [[TaskWrapper alloc] initWithController:self arguments:args];
        NSString *s = [NSString stringWithFormat:@"%@", [codeBox string]];
        [task sendData:[s dataUsingEncoding:NSASCIIStringEncoding]];
        [task startProcess];
    } else {
        [task stopProcess];
    }
}

// Toggle between standard and "html" output views
- (IBAction)HTMLOutputToggle:(id)sender {
    if ([sender state] == NSOnState) {
        [webKitView setHidden:NO];
        [resultBox setHidden:YES];
        [[webKitView mainFrame] loadHTMLString:html baseURL:[NSURL URLWithString:@"file:///"]];
        HTMLOutput = YES;
    } else {
        [webKitView setHidden:YES];
        [resultBox setHidden:NO];
        HTMLOutput = NO;
    }
}

- (void)awakeFromNib {
    lineNumberView = [[MarkerLineNumberView alloc] initWithScrollView:scrollView];
    [scrollView setVerticalRulerView:lineNumberView];
    [scrollView setHasHorizontalRuler:NO];
    [scrollView setHasVerticalRuler:YES];
    [scrollView setRulersVisible:YES];
	
    selectedThing = -1;
    //[codeBox setFont:[NSFont userFixedPitchFontOfSize:[NSFont smallSystemFontSize]]];
    //[resultBox setFont:[NSFont userFixedPitchFontOfSize:[NSFont smallSystemFontSize]]];
    /*compControl = [[CompletionController alloc] init];
    [codeBox setDelegate:compControl];*/
}

- (void)showPHPErrorExplanation {
    if ([[NSUserDefaults standardUserDefaults] integerForKey:@"show_error"] == 0) {
        return;
    }
    NSString *errorType = [[[html componentsSeparatedByString:@":"] objectAtIndex:0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *errorMsg;
    if (![errorType isEqualToString:html]) {
        NSString *tmp;
        tmp = [[html componentsSeparatedByString:@":"] objectAtIndex:[[html componentsSeparatedByString:@":"] count]-1];
        errorMsg = [tmp stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    } else {
        errorType = @"Unknown";
        errorMsg = @"The PHP intrepreter gave us a non-zero exit status, but I couldn't find any specific error information. Sorry!";
    }
    [[NSAlert alertWithMessageText:errorType defaultButton:@"OK" alternateButton:@"" otherButton:@"" informativeTextWithFormat:errorMsg] runModal];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Editable / Selectable
	[codeBox setEditable:YES]; [codeBox setSelectable:YES];
    [resultBox setEditable:NO]; [resultBox setSelectable:YES];
	
	// Init Content
    [[codeBox textStorage] setAttributedString:[[NSAttributedString alloc] initWithString:@"<?php\ninclude(\"error_handling.php\");\n\n?>"]];
    NSRange range = { 37, 0 };
    [codeBox setSelectedRange:range];
	
	// Default Typography
    [codeBox setFont:[NSFont fontWithName:@"Monaco" size:10]];
    [resultBox setFont:[NSFont fontWithName:@"Monaco" size:10]];
    //HTMLOutput = NO;
	
	// Init HTML
    html = [[NSMutableString alloc] initWithCapacity:100000]; //a little under 100kb
    
    // Load prefs
    if ([[NSUserDefaults standardUserDefaults] integerForKey:@"default_output"] == 0) {
        // plain-text output
        HTMLOutput = NO;
    } else {
        HTMLOutput = YES;
        [webKitView setHidden:NO];
        [resultBox setHidden:YES];
        [toggleButton setState:NSOnState];
    }
    
    [codeBox setAllowsUndo:YES];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication {
    return YES;
}

- (void)appendOutput:(NSString *)output {
    [[[resultBox textStorage] mutableString] appendString: output];
	[resultBox setTextColor:[NSColor whiteColor]];
    [resultBox setFont:[NSFont fontWithName:@"Monaco" size:10]];
    NSRange range;
    range = NSMakeRange ([[resultBox string] length], 0);
    [resultBox scrollRangeToVisible: range];
    [html appendString:output];
    if (HTMLOutput) {
        [[webKitView mainFrame] loadHTMLString:html baseURL:[NSURL URLWithString:@"file:///"]];
    }
}

- (void)processStarted {
    [html setString:@""];
    [resultBox setString:@""];
    [statusText setStringValue:@"PHP: working..."];
    //[execButton setEnabled:NO];
    [execButton setTitle:@"Cancel"];
    [execButton setKeyEquivalent:@"."];
}

- (void)processFinished:(int)terminationStatus {
    [statusText setStringValue:[NSString stringWithFormat:@"PHP: Exited with status %d", terminationStatus]];
    unichar hello[2] = {13,0};
    //[execButton setEnabled:YES];
    [execButton setKeyEquivalent:[NSString stringWithCharacters:hello length:1]];
    [execButton setTitle:@"Execute"];
    [NSApp requestUserAttention:NSInformationalRequest];
    if (HTMLOutput) {
        [[webKitView mainFrame] loadHTMLString:html baseURL:[NSURL URLWithString:@"file:///"]];
    }
    if (selectedThing != -1) {
        [lineNumberView placeMarkerAtLine:selectedThing]; // deselects
    }
    selectedThing = 0;
    if (terminationStatus != 0) { // we probably have an error
        NSArray *tokens = [html componentsSeparatedByString:@" "];
        selectedThing = [[tokens lastObject] integerValue];
        [lineNumberView placeMarkerAtLine:[[tokens lastObject] integerValue]];
        [self showPHPErrorExplanation];
    } else {
        selectedThing = -1;
    }
}

@end
