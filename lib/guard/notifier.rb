require 'sys/uname'
require 'pathname'

case Sys::Uname.sysname
when 'Darwin'
  require 'growl'
when 'Linux'
  require 'libnotify'
end

module Guard
  module Notifier
    
    def self.notify(message, options = {})
      unless ENV["GUARD_ENV"] == "test"
        image = options[:image] || :success
        title = options[:title] || "Guard"
        case Sys::Uname.sysname
        when 'Darwin'
          Growl.notify message, :title => title, :icon => image_path(image), :name => "Guard"
        when 'Linux'
          Libnotify.show :body => message, :summary => title, :icon_path => image_path(image)
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
    
  end
end