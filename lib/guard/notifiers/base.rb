require 'rbconfig'
require 'guard/ui'

module Guard
  module Notifier

    # Base class for all notifiers.
    #
    class Base

      HOSTS = {
        darwin:  'Mac OS X',
        linux:   'Linux',
        freebsd: 'FreeBSD',
        openbsd: 'OpenBSD',
        sunos:   'SunOS',
        solaris: 'Solaris',
        mswin:   'Windows',
        mingw:   'Windows',
        cygwin:  'Windows'
      }

      attr_reader :options

      def initialize(opts = {})
        @options = opts
      end

      # This method should be overriden by subclasses and return an array of
      # OSes the notifier supports. By default, it returns :all which mean
      # there's no check against the current OS.
      #
      # @see HOSTS for the list of possible OSes
      #
      def self.supported_hosts
        :all
      end

      # Test if the notifier can be used.
      #
      # @param [Hash] opts notifier options
      # @option opts [Boolean] silent true if no error messages should be shown
      # @return [Boolean] the availability status
      #
      def self.available?(opts = {})
        if _supported_host?
          true
        else
          hosts = supported_hosts.map { |host| HOSTS[host.to_sym] }.join(', ')
          ::Guard::UI.error "The :#{name} notifier runs only on #{hosts}." unless opts.fetch(:silent) { false }
          false
        end
      end

      # This method must be overriden.
      #
      def notify(message, opts = {})
        options.delete(:silent)
        opts.replace(options.merge(opts))
        normalize_standard_options!(opts)
      end

      # Returns the title of the notifier.
      #
      # @example Un-modulize the class name
      #   Guard::Notifier::FileNotifier.title
      #   #=> 'FileNotifier'
      #
      # @return [String] the title of the notifier
      #
      def self.title
        self.to_s.sub(/.+::(\w+)$/, '\1')
      end

      # Returns the name of the notifier.
      #
      # @example Un-modulize, underscorize and downcase the class name
      #   Guard::Notifier::FileNotifier.name
      #   #=> 'file_notifier'
      #
      # @return [String] the name of the notifier
      #
      def self.name
        title.gsub(/([a-z])([A-Z])/, '\1_\2').downcase
      end

      # Returns the name of the notifier's gem. By default it returns the
      # notifier name. This method can be overriden by subclasses.
      #
      # @example Un-modulize, underscorize and downcase the class name
      #   Guard::Notifier::FileNotifier.gem_name
      #   #=> 'file_notifier'
      #
      # @return [String] the name of the notifier's gem
      #
      def self.gem_name
        name
      end

      # This method tries to require the gem whose name is returned by
      # `.gem_name`. If a LoadError or NameError occurs, it displays an error
      # message (unless opts[:silent] is true) and returns false.
      #
      # @param [Hash] opts some options
      # @option opts [Boolean] silent true if no error messages should be shown
      #
      # @return [Boolean] whether or not the gem is loaded
      #
      def self.require_gem_safely(opts = {})
        require gem_name
        true
      rescue LoadError, NameError
        unless opts[:silent]
          ::Guard::UI.error "Please add \"gem '#{gem_name}'\" to your Gemfile and run Guard with \"bundle exec\"."
        end
        false
      end

      # Returns the title of the notifier.
      #
      # @example Un-modulize the class name
      #   Guard::Notifier::FileNotifier.new.title
      #   #=> 'FileNotifier'
      #
      # @return [String] the title of the notifier
      #
      def title
        self.class.title
      end

      # Returns the name of the notifier.
      #
      # @example Un-modulize, underscorize and downcase the class name
      #   Guard::Notifier::FileNotifier.new.name
      #   #=> 'file_notifier'
      #
      # @return [String] the name of the notifier
      #
      def name
        self.class.name
      end

      # Paths where all Guard images are located
      #
      # @return [Pathname] the path to the images directory
      #
      def images_path
        @images_path ||= Pathname.new(File.dirname(__FILE__)).join('../../../images')
      end

      # @private
      #
      # Checks if the current OS is supported by the notifier.
      #
      # @see .supported_hosts
      #
      def self._supported_host?
        supported_hosts == :all ||
        RbConfig::CONFIG['host_os'] =~ /#{supported_hosts.join('|')}/
      end

      # Set or modify the `:title`, `:type` and `:image` options for a
      # notification. Should be used in `#notify`.
      #
      # @param [Hash] opts additional notification library options
      # @option opts [String] type the notification type. Either 'success',
      #   'pending', 'failed' or 'notify'
      # @option opts [String] title the notification title
      # @option opts [String] image the path to the notification image
      #
      def normalize_standard_options!(opts)
        opts[:title] ||= 'Guard'
        opts[:type]  ||= _notification_type(opts.fetch(:image, :success))
        opts[:image]   = _image_path(opts.delete(:image) { :success })
      end

      private

      # Get the image path for an image symbol for the following
      # known image types:
      #
      # - failed
      # - pending
      # - success
      #
      # If the image is not a known symbol, it will be returned unmodified.
      #
      # @param [Symbol, String] image the image symbol or path to an image
      #
      # @return [String] the image path
      #
      def _image_path(image)
        case image
        when :failed, :pending, :success
          images_path.join("#{image.to_s}.png").to_s
        else
          image
        end
      end

      # Get the notification type depending on the
      # image that has been selected for the notification.
      #
      # @param [Symbol, String] image the image symbol or path to an image
      #
      # @return [String] the notification type
      #
      def _notification_type(image)
        case image
        when :failed, :pending, :success
          image
        else
          :notify
        end
      end

    end

  end
end
