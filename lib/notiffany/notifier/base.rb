require "rbconfig"

module Notiffany
  module Notifier
    class Base
      HOSTS = {
        darwin:  "Mac OS X",
        linux:   "Linux",
        freebsd: "FreeBSD",
        openbsd: "OpenBSD",
        sunos:   "SunOS",
        solaris: "Solaris",
        mswin:   "Windows",
        mingw:   "Windows",
        cygwin:  "Windows"
      }

      ERROR_ADD_GEM_AND_RUN_BUNDLE = "Please add \"gem '%s'\" to your Gemfile "\
        "and run your app with \"bundle exec\"."

      def initialize(ui, opts = {})
        options = opts.dup
        @silence_warnings = options.delete(:silent)
        @options =
          { title: "Notiffany" }.
          merge(self.class.const_get(:DEFAULTS)).
          merge(options).freeze

        @ui = ui
        @images_path = Pathname.new(__FILE__).dirname + "../../../images"
      end

      def supported_hosts
        :all
      end

      def available?
        return true if supported_hosts == :all
        return true if RbConfig::CONFIG["host_os"] =~ /#{supported_hosts * '|'}/

        hosts = supported_hosts.map { |host| HOSTS[host.to_sym] }.join(", ")
        @ui.error("The :#{name} notifier runs only on #{hosts}.") unless silent?
        false
      end

      def notify(message, opts = {})
        new_opts = _notify_options(opts)
        _perform_notify(message, new_opts)
      end

      def title
        self.class.to_s[/.+::(\w+)$/, 1]
      end

      def name
        title.gsub(/([a-z])([A-Z])/, '\1_\2').downcase
      end

      def gem_name
        name
      end

      def silent?
        @silence_warnings
      end

      protected

      def require_gem_safely
        Kernel.require gem_name
        true
      rescue LoadError, NameError
        @ui.error(ERROR_ADD_GEM_AND_RUN_BUNDLE % [gem_name]) unless silent?
        false
      end

      private

      def _perform_notify(_message, _opts)
        fail NotImplementedError
      end

      def _image_path(image)
        images = [:failed, :pending, :success, :guard]
        images.include?(image) ? @images_path.join("#{image}.png").to_s : image
      end

      def _notification_type(image)
        [:failed, :pending, :success].include?(image) ? image : :notify
      end

      def _notify_options(overrides = {})
        opts = @options.merge(overrides)
        img_type = opts.fetch(:image, :success)
        opts[:type] ||= _notification_type(img_type)
        opts[:image] = _image_path(img_type)
        opts
      end
    end
  end
end
