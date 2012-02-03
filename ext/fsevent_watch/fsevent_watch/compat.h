/**
 * @headerfile compat.h
 * FSEventStream flag compatibility shim
 *
 * In order to compile a binary against an older SDK yet still support the
 * features present in later OS releases, we need to define any missing enum
 * constants not present in the older SDK. This allows us to safely defer
 * feature detection to runtime (and avoid recompilation).
 */


#ifndef fsevent_watch_compat_h
#define fsevent_watch_compat_h

#ifndef __CORESERVICES__
#include <CoreServices/CoreServices.h>
#endif // __CORESERVICES__

#if MAC_OS_X_VERSION_MAX_ALLOWED < 1060
// ignoring events originating from the current process introduced in 10.6
extern FSEventStreamCreateFlags kFSEventStreamCreateFlagIgnoreSelf;
#endif

#if MAC_OS_X_VERSION_MAX_ALLOWED < 1070
// file-level events introduced in 10.7
extern FSEventStreamCreateFlags kFSEventStreamCreateFlagFileEvents;
extern FSEventStreamEventFlags  kFSEventStreamEventFlagItemCreated,
                                kFSEventStreamEventFlagItemRemoved,
                                kFSEventStreamEventFlagItemInodeMetaMod,
                                kFSEventStreamEventFlagItemRenamed,
                                kFSEventStreamEventFlagItemModified,
                                kFSEventStreamEventFlagItemFinderInfoMod,
                                kFSEventStreamEventFlagItemChangeOwner,
                                kFSEventStreamEventFlagItemXattrMod,
                                kFSEventStreamEventFlagItemIsFile,
                                kFSEventStreamEventFlagItemIsDir,
                                kFSEventStreamEventFlagItemIsSymlink;
#endif

#endif // fsevent_watch_compat_h
