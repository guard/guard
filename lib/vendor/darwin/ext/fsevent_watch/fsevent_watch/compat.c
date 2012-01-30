#include "compat.h"

#if MAC_OS_X_VERSION_MAX_ALLOWED < 1060
FSEventStreamCreateFlags  kFSEventStreamCreateFlagIgnoreSelf        = 0x00000008;
#endif

#if MAC_OS_X_VERSION_MAX_ALLOWED < 1070
FSEventStreamCreateFlags  kFSEventStreamCreateFlagFileEvents        = 0x00000010;
FSEventStreamEventFlags   kFSEventStreamEventFlagItemCreated        = 0x00000100;
FSEventStreamEventFlags   kFSEventStreamEventFlagItemRemoved        = 0x00000200;
FSEventStreamEventFlags   kFSEventStreamEventFlagItemInodeMetaMod   = 0x00000400;
FSEventStreamEventFlags   kFSEventStreamEventFlagItemRenamed        = 0x00000800;
FSEventStreamEventFlags   kFSEventStreamEventFlagItemModified       = 0x00001000;
FSEventStreamEventFlags   kFSEventStreamEventFlagItemFinderInfoMod  = 0x00002000;
FSEventStreamEventFlags   kFSEventStreamEventFlagItemChangeOwner    = 0x00004000;
FSEventStreamEventFlags   kFSEventStreamEventFlagItemXattrMod       = 0x00008000;
FSEventStreamEventFlags   kFSEventStreamEventFlagItemIsFile         = 0x00010000;
FSEventStreamEventFlags   kFSEventStreamEventFlagItemIsDir          = 0x00020000;
FSEventStreamEventFlags   kFSEventStreamEventFlagItemIsSymlink      = 0x00040000;
#endif
