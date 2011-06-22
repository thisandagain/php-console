#import <Cocoa/Cocoa.h>

@protocol TaskWrapperController

// Your controller's implementation of this method will be called when output arrives from the NSTask.
// Output will come from both stdout and stderr, per the TaskWrapper implementation.
- (void)appendOutput:(NSString *)output;

// This method is a callback which your controller can use to do other initialization when a process
// is launched.
- (void)processStarted;

// This method is a callback which your controller can use to do other cleanup when a process
// is halted.
- (void)processFinished:(int)terminationStatus;

@end

@interface TaskWrapper : NSObject {
    NSTask       *task;
    id        <TaskWrapperController>controller;
    NSArray      *arguments;
    NSData *dataToSend;
}

// This is the designated initializer - pass in your controller and any task arguments.
// The first argument should be the path to the executable to launch with the NSTask.
- (id)initWithController:(id <TaskWrapperController>)controller arguments:(NSArray *)args;

// We want to be able to pass data to the task:
- (void)sendData:(NSData*)theData;

// This method launches the process, setting up asynchronous feedback notifications.
- (void) startProcess;

// This method stops the process, stoping asynchronous feedback notifications.
- (void) stopProcess;

@end
