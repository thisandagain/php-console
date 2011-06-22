#import "NoodleLineNumberView.h"
#import "NoodleLineNumberMarker.h"
#import "MarkerLineNumberView.h"
#import "ColoringController.h"

#import "flextokens.h"

#define COMPLETION_DELAY (0.5)

@implementation ColoringController
- (void)awakeFromNib
{
    NSScanner *scanner;
    NSString *word;
    NSString *file;
    NSCharacterSet *whiteSpaceSet;

    [[textview textStorage] setDelegate:self];

    // load our dictionary
    whiteSpaceSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    words = [[NSMutableArray alloc] init];
    file = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"PHP Keywords" ofType:@"txt"]];
    if (!file) return; // error
    scanner = [NSScanner scannerWithString:file];
    while (![scanner isAtEnd]) {
        BOOL ok;
        ok = [scanner scanUpToCharactersFromSet:whiteSpaceSet
                                     intoString:&word];
        if (ok)
            [words addObject:word];
    }
    [textview setDelegate:self];
}

- (NSMutableArray*)getWordArray {
    return words;
}

- (void)textStorageDidProcessEditing:(NSNotification *)notification
{
    NSTextStorage *textStorage = [notification object];
    NSString *string = [textStorage string];
    NSRange area = [textStorage editedRange];
    unsigned int length = [string length];
    NSRange start, end;
    NSMutableCharacterSet *whiteSpaceSet;
    unsigned int areamax = NSMaxRange(area);
    NSRange found;
    NSColor *keywordColor = [NSUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] objectForKey:@"colors_keyword"]];
    
    //NSColor *red = [NSColor redColor];
    NSString *word;
    // extend our range along word boundaries.
    whiteSpaceSet = [NSMutableCharacterSet characterSetWithCharactersInString:@"()[]{}:;"];
    [whiteSpaceSet formUnionWithCharacterSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    start = [string rangeOfCharacterFromSet:whiteSpaceSet
                                    options:NSBackwardsSearch
                                      range:NSMakeRange(0, area.location)];
    if (start.location == NSNotFound) {
        start.location = 0;
    }  else {
        start.location = NSMaxRange(start);
    }
    end = [string rangeOfCharacterFromSet:whiteSpaceSet
                                  options:0
                                    range:NSMakeRange(areamax, length - areamax)];
    if (end.location == NSNotFound)
        end.location = length;
    area = NSMakeRange(start.location, end.location - start.location);
    if (area.length == 0) return; // bail early
    
    // remove the old colors
    [textStorage removeAttribute:NSForegroundColorAttributeName range:area];

    // add new colors
    while (area.length) {
        // find the next word
        end = [string rangeOfCharacterFromSet:whiteSpaceSet
                                      options:0
                                        range:area];
        if (end.location == NSNotFound) {
            end = found = area;
        } else {
            found.length = end.location - area.location;
            found.location = area.location;
        }
        word = [string substringWithRange:found];
        // color as necessary
        if (([word length] > 0) && ([word characterAtIndex:0] == '$')) {
            word = [word lowercaseString];
        }
        if ([words indexOfObject:word] != NSNotFound) {
            [textStorage addAttribute:NSForegroundColorAttributeName
                                value:keywordColor
                                range:found];
        } else if ([word isEqualToString:@"<?php"] || [word isEqualToString:@"?>"]) {
            [textStorage addAttribute:NSForegroundColorAttributeName
                                value:[NSColor redColor]
                                range:found];
        }
        
        // adjust our area
        areamax = NSMaxRange(end);
        area.length -= areamax - area.location;
        area.location = areamax;
    }
    
    
    extern char *yytext;            // pointer to string of current token
    //extern double realvalue;        // value of real number if token == REAL
    NSUInteger poscounter = 0;      // position counter
    NSUInteger token = 0;           // the token
    //double total = 0.;              // total amount
    
    // reset scanner state
    yystatereset();
    
    // scan string
    yy_scan_string([string UTF8String]);
    
    NSColor *stringColor = [NSUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] objectForKey:@"colors_strings"]];
    NSColor *variableColor = [NSUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] objectForKey:@"colors_variables"]];
    NSColor *commentColor = [NSUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] objectForKey:@"colors_comments"]];
    
    // fetch tokens from scanner
    while (token = yylex()) {
        // transform C string back to NSString to read UTF-8 characters
        NSString *tokenstring = [NSString stringWithUTF8String:yytext];
        //NSLog(@"tokenstring = %@", tokenstring);
        // range of string matched by token
        NSRange range = NSMakeRange(poscounter, [tokenstring length]);
        
        // standard color
        NSColor *color = [NSColor blackColor];
        
        // new position counter
        poscounter += [tokenstring length];
        
        // token constants defined in flextokens.h
        // set new color and calculate total value
        if (token == INSIDE_QUOTES) {
            color = stringColor;
        } else if (token == SINGLE_INSIDE_QUOTES) {
            color = stringColor;
        } else if (token == COMMENTED) {
            //color = [NSColor colorWithCalibratedRed:0.2 green:0.5 blue:0.2 alpha:1];
            color = commentColor;
        } else if (token == VARIABLE) {
            //color = [NSColor colorWithCalibratedRed:0.2 green:0.2 blue:0.4 alpha:1];
            color = variableColor;
        } else {
            continue;
        }
        
        // apply new color to text range
        [textStorage addAttribute:NSForegroundColorAttributeName
                            value:color
                            range:range];
        
    }
    
}

- (void)doCompletion:(NSTimer *)timer {
    [self stopCompletionTimer];
    [textview complete:nil];
}

- (void)startCompletionTimer {
    if ([[NSUserDefaults standardUserDefaults] integerForKey:@"autocomplete"] == 0) {
        return;
    }
    [self stopCompletionTimer];
    completionTimer = [[NSTimer scheduledTimerWithTimeInterval:COMPLETION_DELAY target:self selector:@selector(doCompletion:) userInfo:nil repeats:NO] retain];
}

- (BOOL)textView:(NSTextView *)textView shouldChangeTextInRange:(NSRange)affectedCharRange replacementString:(NSString*)replacementString {
    //NSLog(@"%@", replacementString);
    [self startCompletionTimer];
    if ([[replacementString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:@""]) { [self stopCompletionTimer]; }
    //nextInsertionIndex = affectedCharRange.location + [replacementString length];
    return YES;
}

- (void)stopCompletionTimer {
    [completionTimer invalidate];
    [completionTimer release];
    completionTimer = nil;
}

- (NSArray *)control:(NSControl *)control textView:(NSTextView *)textView completions:(NSArray *)the_words
                    forPartialWordRange:(NSRange)charRange indexOfSelectedItem:(NSInteger *)index {
    NSMutableArray *result = [[NSMutableArray alloc] init];
    NSString *string = [[textView string] substringWithRange:charRange];
    NSEnumerator *enumer = [words objectEnumerator];
    NSString *testingString;
    while (testingString = [enumer nextObject]) {
        if ([testingString compare:string options:NSCaseInsensitiveSearch range:NSMakeRange(0, [string length])] == NSOrderedSame) {
            [result addObject:[NSString stringWithString:testingString]];
        }
    }
    //if ([result count] == 1) { return nil; }
    return result;
}

- (NSArray *)textView:(NSTextView *)textView completions:(NSArray *)the_words forPartialWordRange:(NSRange)charRange indexOfSelectedItem:(NSInteger *)index {
    return [self control:nil textView:textView completions:the_words forPartialWordRange:charRange indexOfSelectedItem:index];
}
@end
