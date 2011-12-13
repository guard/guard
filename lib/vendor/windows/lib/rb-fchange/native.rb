require 'ffi'

module FChange
  # This module contains the low-level foreign-function.
  # It's an implementation detail, and not meant for users to deal with.
  #
  # @private
  module Native
    extend FFI::Library
    ffi_lib 'kernel32'
    ffi_convention :stdcall

    # HANDLE FindFirstChangeNotification(
    #  LPCTSTR lpPathName,    // directory name
    #  BOOL bWatchSubtree,    // monitoring option
    #  DWORD dwNotifyFilter   // filter conditions
    #);
    attach_function :FindFirstChangeNotificationW, [:pointer, :int, :long], :long

    # HANDLE FindFirstChangeNotification(
    #  LPCTSTR lpPathName,    // directory name
    #  BOOL bWatchSubtree,    // monitoring option
    #  DWORD dwNotifyFilter   // filter conditions
    #);
    attach_function :FindFirstChangeNotificationA, [:pointer, :int, :long], :long

    # BOOL FindNextChangeNotification(
    #  HANDLE hChangeHandle   // handle to change notification
    # );
    attach_function :FindNextChangeNotification, [:long], :int

    # DAORD WaitForMultipleObjects(
    #   DWORD nCount,             // number of handles in array
    #   CONST HANDLE *lpHandles,  // object-handle array
    #   BOOL bWaitAll,            // wait option
    #   DWORD dwMilliseconds      // time-out interval
    # );
    attach_function :WaitForMultipleObjects, [:long, :pointer, :int, :long], :long

    # BOOL FindCloseChangeNotification(
    #   HANDLE hChangeHandle
    # );
    attach_function :FindCloseChangeNotification, [:long], :int
  end
end
