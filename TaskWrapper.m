#import "TaskWrapper.h"

@implementation TaskWrapper

// Do basic initialization
- (id)initWithController:(id <TaskWrapperController>)cont arguments:(NSArray *)args
{
    self = [super init];
    controller = cont;
    arguments = [args retain];
    
    return self;
}

// tear things down
- (void)dealloc
{
    [self stopProcess];

    [arguments release];
    [task release];
    [super dealloc];
}

// Here's where we actually kick off the process via an NSTask.
- (void) startProcess
{
    // We first let the controller know that we are starting
    [controller processStarted];

    task = [[NSTask alloc] init];
    // The output of stdout and stderr is sent to a pipe so that we can catch it later
    // and send it along to the controller; notice that we don't bother to do anything with stdin,
    // so this class isn't as useful for a task that you need to send info to, not just receive.
    [task setStandardOutput: [NSPipe pipe]];
    [task setStandardInput: [NSPipe pipe]];
    [task setStandardError: [task standardOutput]];
    // The path to the binary is the first argument that was passed in
    [task setLaunchPath: [arguments objectAtIndex:0]];
    [task setCurrentDirectoryPath:[[NSBundle mainBundle] resourcePath]];
    // The rest of the task arguments are just grabbed from the array
    [task setArguments: [arguments subarrayWithRange: NSMakeRange (1, ([arguments count] - 1))]];

    // Here we register as an observer of the NSFileHandleReadCompletionNotification, which lets
    // us know when there is data waiting for us to grab it in the task's file handle (the pipe
    // to which we connected stdout and stderr above).  -getData: will be called when there
    // is data waiting.  The reason we need to do this is because if the file handle gets
    // filled up, the task will block waiting to send data and we'll never get anywhere.
    // So we have to keep reading data from the file handle as we go.
    [[NSNotificationCenter defaultCenter] addObserver:self 
        selector:@selector(getData:) 
        name: NSFileHandleReadCompletionNotification 
        object: [[task standardOutput] fileHandleForReading]];
    // We tell the file handle to go ahead and read in the background asynchronously, and notify
    // us via the callback registered above when we signed up as an observer.  The file handle will
    // send a NSFileHandleReadCompletionNotification when it has data that is available.
    [[[task standardOutput] fileHandleForReading] readInBackgroundAndNotify];

    // launch the task asynchronously
    [task launch];
    if (dataToSend != NULL) {
        [[[task standardInput] fileHandleForWriting] writeData:dataToSend];
        [[[task standardInput] fileHandleForWriting] closeFile];
    }
}

- (void)sendData:(NSData*)theData {
    dataToSend = [NSData dataWithData:theData];
    //[[[task standardInput] fileHandleForWriting] writeData:theData];
}

// If the task ends, there is no more data coming through the file handle even when the notification is
// sent, or the process object is released, then this method is called.
- (void) stopProcess
{
/*    // we tell the controller that we finished, via the callback, and then blow away our connection
    // to the controller.  NSTasks are one-shot (not for reuse), so we might as well be too.
    [controller processFinished];
    controller = nil;*/
    NSData *data;
    
    // It is important to clean up after ourselves so that we don't leave potentially deallocated
    // objects as observers in the notification center; this can lead to crashes.
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSFileHandleReadCompletionNotification object: [[task standardOutput] fileHandleForReading]];
    
    // Make sure the task has actually stopped!
    [task terminate];

   while ((data = [[[task standardOutput] fileHandleForReading] availableData]) && [data length])
   {
       [controller appendOutput: [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease]];
   }
   
   [task waitUntilExit];
   // we tell the controller that we finished, via the callback, and then blow away our connection
   // to the controller.  NSTasks are one-shot (not for reuse), so we might as well be too.
   [controller processFinished:[task terminationStatus]];
   controller = nil;
}

// This method is called asynchronously when data is available from the task's file handle.
// We just pass the data along to the controller as an NSString.
- (void) getData: (NSNotification *)aNotification
{
    NSData *data = [[aNotification userInfo] objectForKey:NSFileHandleNotificationDataItem];
    // If the length of the data is zero, then the task is basically over - there is nothing
    // more to get from the handle so we may as well shut down.
    if ([data length])
    {
        // Send the data on to the controller; we can't just use +stringWithUTF8String: here
        // because -[data bytes] is not necessarily a properly terminated string.
        // -initWithData:encoding: on the other hand checks -[data length]
        [controller appendOutput: [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease]];
    } else {
        // We're finished here
        [self stopProcess];
    }
    
    // we need to schedule the file handle go read more data in the background again.
    [[aNotification object] readInBackgroundAndNotify];  
}

@end