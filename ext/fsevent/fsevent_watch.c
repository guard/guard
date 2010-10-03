#include <CoreServices/CoreServices.h>

void callback(ConstFSEventStreamRef streamRef,
  void *clientCallBackInfo,
  size_t numEvents,
  void *eventPaths,
  const FSEventStreamEventFlags eventFlags[],
  const FSEventStreamEventId eventIds[]
) {
  // Print modified dirs
  int i;
  char **paths = eventPaths;
  for (i = 0; i < numEvents; i++) {
    printf("%s", paths[i]);
    printf(" ");
  }
  printf("\n");
  fflush(stdout);
}

int main (int argc, const char * argv[]) {
  // Create event stream
  CFStringRef pathToWatch = CFStringCreateWithCString(kCFAllocatorDefault, argv[1], kCFStringEncodingUTF8);
  CFArrayRef pathsToWatch = CFArrayCreate(NULL, (const void **)&pathToWatch, 1, NULL);  
  void *callbackInfo = NULL;
  FSEventStreamRef stream;
  CFAbsoluteTime latency = 0.1;
  stream = FSEventStreamCreate(
    kCFAllocatorDefault,
    callback,
    callbackInfo,
    pathsToWatch,
    kFSEventStreamEventIdSinceNow,
    latency,
    kFSEventStreamCreateFlagNone
  );
  
  // Add stream to run loop
  FSEventStreamScheduleWithRunLoop(stream, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
  FSEventStreamStart(stream);
  CFRunLoopRun();
  
  return 2;
}