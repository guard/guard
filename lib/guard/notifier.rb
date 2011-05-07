require 'rbconfig'
require 'pathname'

module Guard
  module Notifier

    def self.turn_off
      @disable = true
    end

    def self.turn_on
      @disable = false
      case Config::CONFIG['target_os']
      when /darwin/i
        require_growl
      when /linux/i
        require_libnotify
      end
    end

    def self.notify(message, options = {})
      unless @disable
        image = options[:image] || :success
        title = options[:title] || "Guard"
        case Config::CONFIG['target_os']
        when /darwin/i
          Growl.notify message, :title => title, :icon => image_path(image), :name => "Guard"
        when /linux/i
          Libnotify.show :body => message, :summary => title, :icon_path => image_path(image)
        end
      end
    end

    def self.disabled?
      @disable
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
      require 'growl'
    rescue LoadError
      @disable = true
      UI.info "Please install growl gem for Mac OS X notification support and add it to your Gemfile"
    end

    def self.require_libnotify
      require 'libnotify'
    rescue LoadError
      @disable = true
      UI.info "Please install libnotify gem for Linux notification support and add it to your Gemfile"
    end

  end
end