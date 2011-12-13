module FChange
  module Native
    # A module containing all the flags to be passed to {Notifier#watch}.
    # @see http://msdn.microsoft.com/en-us/library/aa364417(v=VS.85).aspx 
    # 
    # @private
    module Flags

      # Any file name change in the watched directory or subtree causes a change
      # notification wait operation to return. Changes include renaming, 
      # creating, or deleting a file name.
      FILE_NOTIFY_CHANGE_FILE_NAME   = 0x00000001

      # Any directory-name change in the watched directory or subtree causes a 
      # change notification wait operation to return. Changes include creating 
      # or deleting a directory.
      FILE_NOTIFY_CHANGE_DIR_NAME    = 0x00000002

      # Any attribute change in the watched directory or subtree causes a change
      # notification wait operation to return.
      FILE_NOTIFY_CHANGE_ATTRIBUTES  = 0x00000004

      # Any file-size change in the watched directory or subtree causes a change
      # notification wait operation to return. The operating system detects a 
      # change in file size only when the file is written to the disk. 
      # For operating systems that use extensive caching, detection occurs only 
      # when the cache is sufficiently flushed.
      FILE_NOTIFY_CHANGE_SIZE        = 0x00000008

      # Any change to the last write-time of files in the watched directory or 
      # subtree causes a change notification wait operation to return.
      # The operating system detects a change to the last write-time only when 
      # the file is written to the disk. For operating systems that use 
      # extensive caching, detection occurs only when the cache is sufficiently 
      # flushed
      FILE_NOTIFY_CHANGE_LAST_WRITE  = 0x00000010

      # Any change to the last access time of files in the watched directory or 
      # subtree causes a change notification wait operation to return.
      FILE_NOTIFY_CHANGE_LAST_ACCESS = 0x00000020

      # Any change to the creation time of files in the watched directory or 
      # subtree causes a change notification wait operation to return.
      FILE_NOTIFY_CHANGE_CREATION    = 0x00000040

      # Any security-descriptor change in the watched directory or subtree 
      # causes a change notification wait operation to return.
      FILE_NOTIFY_CHANGE_SECURITY    = 0x00000100

      FILE_NOTIFY_CHANGE_ALL_EVENTS = (
        FILE_NOTIFY_CHANGE_DIR_NAME |
        FILE_NOTIFY_CHANGE_FILE_NAME |
        FILE_NOTIFY_CHANGE_LAST_WRITE
      )

      # Converts a list of flags to the bitmask that the C API expects.
      #
      # @param flags [Array<Symbol>]
      # @return [Fixnum]
      def self.to_mask(flags)
        flags.map {|flag| const_get("FILE_NOTIFY_CHANGE_#{flag.to_s.upcase}")}.
          inject(0) {|mask, flag| mask | flag}
      end

      # Converts a bitmask from the C API into a list of flags.
      #
      # @param mask [Fixnum]
      # @return [Array<Symbol>]
      def self.from_mask(mask)
        constants.map {|c| c.to_s}.select do |c|
          next false unless c =~ /^FILE_NOTIFY_CHANGE_/
          const_get(c) & mask != 0
        end.map {|c| c.sub("FILE_NOTIFY_CHANGE_", "").downcase.to_sym} - [:all_events]
      end

    end
  end
end
