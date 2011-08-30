require 'rbconfig'
require 'pathname'
require 'guard/ui'

module Guard
  module Notifier
    APPLICATION_NAME = "Guard"

    def self.turn_off
      ENV["GUARD_NOTIFY"] = 'false'
    end

    def self.turn_on
      ENV["GUARD_NOTIFY"] = 'true'
      case RbConfig::CONFIG['target_os']
      when /darwin/i
        require_growl
      when /linux/i
        require_libnotify
      when /mswin|mingw/i
        require_rbnotifu
      end
    end

    def self.notify(message, options = {})
      if enabled?
        image = options.delete(:image) || :success
        title = options.delete(:title) || "Guard"

        case RbConfig::CONFIG['target_os']
        when /darwin/i
          notify_mac(title, message, image, options)
        when /linux/i
          notify_linux(title, message, image, options)
        when /mswin|mingw/i
          notify_windows(title, message, image, options)
        end
      end
    end

    def self.enabled?
      ENV["GUARD_NOTIFY"] == 'true'
    end

  private

    def self.notify_mac(title, message, image, options)
      require_growl # need for guard-rspec formatter that is called out of guard scope

      default_options = { :title => title, :icon => image_path(image), :name => APPLICATION_NAME }
      default_options.merge!(options)

      if defined?(GrowlNotify)
        default_options[:description] = message
        default_options[:application_name] = APPLICATION_NAME
        default_options.delete(:name)

        GrowlNotify.send_notification(default_options) if enabled?
      else
        Growl.notify message, default_options.merge(options) if enabled?
      end
    end

    def self.notify_linux(title, message, image, options)
      require_libnotify # need for guard-rspec formatter that is called out of guard scope
      default_options = { :body => message, :summary => title, :icon_path => image_path(image), :transient => true }
      Libnotify.show default_options.merge(options) if enabled?
    end

    def self.notify_windows(title, message, image, options)
      require_rbnotifu # need for guard-rspec formatter that is called out of guard scope
      default_options = { :message => message, :title => title, :type => image_level(image), :time => 3 }
      Notifu.show default_options.merge(options) if enabled?
    end

    def self.image_path(image)
      images_path = Pathname.new(File.dirname(__FILE__)).join('../../images')
      case image
      when :failed
        images_path.join("failed.png").to_s
      when :pending
        images_path.join("pending.png").to_s
      when :success
        images_path.join("success.png").to_s
      else
        # path given
        image
      end
    end

    def self.image_level(image)
      case image
      when :failed
        :error
      when :pending
        :warn
      when :success
        :info
      else
        :info
      end
    end

    def self.require_growl
      begin
        require 'growl_notify'

        if GrowlNotify.application_name != APPLICATION_NAME
          GrowlNotify.config do |c|
            c.notifications = c.default_notifications = [ APPLICATION_NAME ]
            c.application_name = c.notifications.first
          end
        end
      rescue LoadError
        require 'growl'
      end
    rescue LoadError
      turn_off
      UI.info "Please install growl or growl_notify gem for Mac OS X notification support and add it to your Gemfile"
    end

    def self.require_libnotify
      require 'libnotify'
    rescue LoadError
      turn_off
      UI.info "Please install libnotify gem for Linux notification support and add it to your Gemfile"
    end

    def self.require_rbnotifu
      require 'rb-notifu'
    rescue LoadError
      turn_off
      UI.info "Please install rb-notifu gem for Windows notification support and add it to your Gemfile"
    end
  end
end
