require 'guard/ui'

module Guard
  module Notifier

    # Amazon SNS notifications using the [aws-sdk](http://aws.amazon.com/sdkforruby/) gem.
    #
    # You must set AWS_ACCESS_KEY and AWS_SECRET_KEY environment variables with your
    # AWS credentials.
    #
    # @example Add the `aws-sdk` gem to your `Gemfile`
    #   group :development
    #     gem 'aws-sdk'
    #   end
    #
    # Must pass topic ARN in your notification options
    #
    # @example Add the `:growl` notifier to your `Guardfile`
    #   notification :sns, :topic => 'arn::your_topic_arn'
    #
    module Sns
      extend self

      # Default options for growl gem
      DEFAULTS = {
        :access_key => ENV['AWS_ACCESS_KEY'],
        :secret_access_key => ENV['AWS_SECRET_KEY'],
        :silent => false
      }

      # Test if the notification library is available.
      #
      # @param [Boolean] silent true if no error messages should be shown
      # @return [Boolean] the availability status
      #
      def available?(silent = false)
        
        require 'aws-sdk'

        if !ENV['AWS_ACCESS_KEY'] or !ENV['AWS_SECRET_KEY']
          ::Guard::UI.error "Please set AWS_ACCESS_KEY and AWS_SECRET_KEY environment variables." unless silent
          false
        else
          true
        end

      rescue LoadError, NameError
        ::Guard::UI.error "Please add \"gem 'aws-sdk'\" to your Gemfile and run Guard with \"bundle exec\"." unless silent
        false
      end

      # Send a Amazon SNS notification.
      #
      # @param [String] type the notification type. Either 'success', 'pending', 'failed' or 'notify'
      # @param [String] title the notification title
      # @param [String] message the notification message body
      # @param [String] image the path to the notification image
      # @param [Hash] options additional notification library options
      # @option MANDATORY [String] topic the ARN of the SNS topic you want to publish to
      # @option options [String] access_key AWS access_key to use (default is taken from env var AWS_ACCESS_KEY)
      # @option options [String] secret_access_key AWS secret_access_key to use (default is taken from env var AWS_SECRET_KEY)
      # @option options [Boolean] silent true if no error messages should be shown
      #
      def notify(type, title, message, image, options = { })
        require 'aws-sdk'
        opts = DEFAULTS.merge(options)
        
        if(!opts[:topic])
          ::Guard::UI.error "Must specify a SNS topic in options[:topic]" unless opts[:silent]
          return false
        end

        aws = AWS::SNS.new(:access_key_id => opts[:access_key], :secret_access_key => opts[:secret_access_key])
        topic = aws.topics[opts[:topic]]
        topic.publish(message, {:subject => title})
      end

    end
  end
end
