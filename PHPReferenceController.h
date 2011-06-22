#import <Cocoa/Cocoa.h>

@interface PHPReferenceController : NSObject {
    IBOutlet id code;
}

- (IBAction)accessRefs:(id)sender;
- (NSString *) urlencode: (NSString *) url;
@end
