require 'rbconfig'
require 'pathname'

module Guard
  module UI
    class Notifier
      
      def report(type, message, options)
        notify message, :image => type
      end
    
      def notify(message, options = {})
        unless ENV["GUARD_ENV"] == "test"
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
    
      def image_path(image)
        images_path = Pathname.new(File.dirname(__FILE__)).join('../../../images')
        case image
        when :failure
          images_path.join("failed.png").to_s
        when :info
          images_path.join("pending.png").to_s
        when :success
          images_path.join("success.png").to_s
        when :debug
          images_path.join("pending.png").to_s
        end
      end
    
      def growl_installed?
        @installed ||= begin
          require 'growl'
          true
        rescue LoadError
          ::Guard.info "Please install growl gem for Mac OS X notification support and add it to your Gemfile"
          false
        end
      end
    
      def libnotify_installed?
        @installed ||= begin
          require 'libnotify'
          true
        rescue LoadError
          ::Guard.info "Please install libnotify gem for Linux notification support and add it to your Gemfile"
          false
        end
      end
    
    end
  end
end