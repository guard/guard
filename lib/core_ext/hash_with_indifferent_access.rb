class Thor
  module CoreExt #:nodoc:
    class HashWithIndifferentAccess < ::Hash #:nodoc:
      def has_key?(key)
        super(convert_key(key))
      end
    end
  end
end
