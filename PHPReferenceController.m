#import "PHPReferenceController.h"

@implementation PHPReferenceController
- (IBAction)accessRefs:(id)sender {
    NSString *sel_text = [[code string] substringWithRange:[code selectedRange]];
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://www.php.net/manual-lookup.php?pattern=%@", [self urlencode:sel_text]]];
    [[NSWorkspace sharedWorkspace] openURL:url];
}

- (NSString *) urlencode: (NSString *) url
{
    NSArray *escapeChars = [NSArray arrayWithObjects:@";" , @"/" , @"?" , @":" ,
                                                        @"@" , @"&" , @"=" , @"+" ,
                                                        @"$" , @"," , @"[" , @"]",
                                                        @"#", @"!", @"'", @"(", 
                                                        @")", @"*", nil];

    NSArray *replaceChars = [NSArray arrayWithObjects:@"%3B" , @"%2F" , @"%3F" ,
                                                        @"%3A" , @"%40" , @"%26" ,
                                                        @"%3D" , @"%2B" , @"%24" ,
                                                        @"%2C" , @"%5B" , @"%5D", 
                                                        @"%23", @"%21", @"%27",
                                                        @"%28", @"%29", @"%2A", nil];

    int len = [escapeChars count];

    NSMutableString *temp = [url mutableCopy];

    int i;
    for(i = 0; i < len; i++)
    {

        [temp replaceOccurrencesOfString: [escapeChars objectAtIndex:i]
                                    withString:[replaceChars objectAtIndex:i]
                                    options:NSLiteralSearch
                                    range:NSMakeRange(0, [temp length])];
    }

    NSString *out = [NSString stringWithString: temp];

    return out;
}
@end
