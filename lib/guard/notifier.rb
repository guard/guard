require 'rbconfig'
require 'pathname'

module Guard
  module Notifier
    @enabled = false

    @enable = false
    @library = false

    def self.turn_off
      @enable = false
    end

    def self.turn_on
      @enable = true

      return true if @library  #only do require_ once.

      case Config::CONFIG['target_os']
      when /darwin/i
        require_growl
      when /linux/i
        require_libnotify
      end
    end

    def self.should_send?
      @enable && !!installed_lib
    end

    def self.disabled?
      not should_send?
    end

    def self.installed_lib
      @library
    end
    
    def self.notify(message, options = {})
      if should_send?()
        image = options[:image] || :success
        title = options[:title] || "Guard"
        case @library
        when :growl
          if growl_installed?
            Growl.notify message, :title => title, :icon => image_path(image), :name => "Guard"
          end
        when :libnotify
          if libnotify_installed?
            Libnotify.show :body => message, :summary => title, :icon_path => image_path(image)
          end
        end
      end
    end


  private

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

    def self.require_growl
      @installed ||= begin
        require 'growl'
        @library = :growl
      rescue LoadError
        UI.info "Please install growl gem for Mac OS X notification support and add it to your Gemfile"
        @enable = false
      end
    end

    def self.require_libnotify
      @installed ||= begin
        require 'libnotify'
        @library = :libnotify
      rescue LoadError
        UI.info "Please install libnotify gem for Linux notification support and add it to your Gemfile"
        @enable = false
      end
    end

  end
end