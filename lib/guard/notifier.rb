require 'rbconfig'
require 'pathname'

case Config::CONFIG['target_os']
when /darwin/i
  require 'growl'
when /linux/i
  require 'libnotify'
end

module Guard
  module Notifier
    
    def self.notify(message, options = {})
      unless ENV["GUARD_ENV"] == "test"
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