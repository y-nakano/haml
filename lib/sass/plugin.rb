require File.dirname(__FILE__) + '/../sass'
require 'sass/engine'

require 'rubygems'
require 'action_controller'

module Sass
  # This module contains methods that ActionController calls
  # to automatically update Sass templates that need updating.
  # It wasn't designed to be used outside of the context of ActionController.
  module Plugin
    class << self
      @@options = {
        :template_location  => RAILS_ROOT + '/public/stylesheets/sass',
        :css_location       => RAILS_ROOT + '/public/stylesheets',
        :always_update      => false,
        :always_check       => RAILS_ENV != "production",
        :style              => :nested
      }

      # Gets various options for Sass. See REFERENCE for details.
      #--
      # TODO: *DOCUMENT OPTIONS*
      #++
      def options
        @@options
      end

      # Sets various options for Sass.
      def options=(value)
        @@options.merge!(value)
      end
      
      # Checks each stylesheet in <tt>options[:css_location]</tt>
      # to see if it needs updating,
      # and updates it using the corresponding template
      # from <tt>options[:templates]</tt>
      # if it does.
      def update_stylesheets
        Dir[options[:template_location] + '/*.sass'].each do |file|
          name = File.basename(file)[0...-5]
          
          if options[:always_update] || stylesheet_needs_update?(name)
            css = css_filename(name)
            File.delete(css) if File.exists?(css)
            
            engine = Engine.new(File.read(template_filename(name)), @@options.dup)
            result = engine.render
            
            Dir.mkdir(options[:css_location]) unless File.exist?(options[:css_location])
            File.open(css, 'w') do |file|
              file.print(result)
            end
          end
        end
      end
      
      private
      
      def template_filename(name)
        "#{@@options[:template_location]}/#{name}.sass"
      end
      
      def css_filename(name)
        "#{@@options[:css_location]}/#{name}.css"
      end
      
      def stylesheet_needs_update?(name)
        !File.exists?(css_filename(name)) || (File.mtime(template_filename(name)) - 2) > File.mtime(css_filename(name))
      end
    end
  end
end

# This module refers to the ActionController module that's part of Ruby on Rails.
# Sass can be used as an alternate templating engine for Rails,
# and includes some modifications to make this more doable.
# The documentation can be found
# here[http://rubyonrails.org/api/classes/ActionController/Base.html].
module ActionController
  class Base # :nodoc:
    alias_method :sass_old_process, :process
    def process(*args)
      Sass::Plugin.update_stylesheets if Sass::Plugin.options[:always_update] || Sass::Plugin.options[:always_check]
      sass_old_process(*args)
    end
  end
end