require 'rbconfig'
require 'pathname'
require 'guard/guard'

module Guard
  module Notifier    
    
    def self.notify(message, options = {})
      puts "DEPRECATED: you should use ::Guard.success, ::Guard.error or ::Guard.info instead of Notifier.notify."
      if options.include?(:image) && options[:image].kind_of?(Symbol)
        case(options[:image])
        when :failed
          type = :failure
        when :error
          type = :failure
        when :pending
          type = :info
        else
          type = options[:image]
        end
      else
        type = :success
      end
      ::Guard.report(type, message)
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