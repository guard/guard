require 'rbconfig'
require 'pathname'

module Guard
  module Notifier

    def self.turn_off
      @disable = true
    end

    def self.notify(message, options = {})
      unless @disable || ENV["GUARD_ENV"] == "test"
        image = options[:image] || :success
        title = options[:title] || "Guard"
        case Config::CONFIG['target_os']
        when /darwin/i
          if growl_installed?
            Growl.notify message, :title => title, :icon => image_path(image), :name => "Guard"
          end
        when /linux/i
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

    def self.growl_installed?
      @installed ||= begin
        require 'growl'
        true
      rescue LoadError
        UI.info "Please install growl gem for Mac OS X notification support and add it to your Gemfile"
        false
      end
    end

    def self.libnotify_installed?
      @installed ||= begin
        require 'libnotify'
        true
      rescue LoadError
        UI.info "Please install libnotify gem for Linux notification support and add it to your Gemfile"
        false
      end
    end

  end
end