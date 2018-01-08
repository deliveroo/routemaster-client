require 'routemaster/cli/helper'
require 'optparse'
require 'hashie'

module Routemaster
  module CLI
    class Base
      def self.inherited(by)
        by.extend(ClassMethods)
      end

      module ClassMethods
        def prefix(ary = nil)
          @prefix ||= ary
        end

        def syntax(string = nil)
          string ? (@syntax = string) : ['rtm', *@prefix, @syntax, '[options]'].compact.join(' ')
        end

        def descr(string = nil)
          string ? (@descr = string) : @descr
        end

        def defaults(hash = nil)
          hash ? (@defaults = hash) : (@defaults || {})
        end

        def options(&block)
          block_given? ? (@options = block) : @options
        end

        def action(&block)
          block_given? ? (@action = block) : @action || lambda { |*| }
        end

        def config
          @config ||= Hashie::Mash.new(_default_options).merge(defaults)
        end

        private

        def _default_options
          { verbose: false }
        end
      end

      def initialize(stderr:, stdout:)
        @stderr = stderr
        @stdout = stdout
      end

      def run(argv)
        @argv = argv
        _parser.parse!(@argv)
        instance_eval(&self.class.action)
      rescue Exit
        raise
      rescue StandardError => e
        log "#{e.class.name}: #{e.message}"
        if config.verbose
          e.backtrace.each { |l| log "\t#{l}" }
        end
        raise Exit, 2
      end

      protected

      def argv
        @argv || []
      end

      def config
        self.class.config
      end

      def helper
        Helper.new(config)
      end

      def log(message)
        @stderr.puts(message)
      end

      def puts(message)
        @stdout.puts(message)
      end

      def usage!
        log "Usage:"
        log _parser
        raise Exit, 1
      end

      def bad_argc!
        log "Wrong number of arguments."
        usage!
      end

      private

      def _parser
        @parser ||= OptionParser.new do |p|
          p.banner = self.class.syntax
          p.separator self.class.descr

          if self.class.options
            p.separator 'Options:'
            self.class.options.call(p)
          end

          p.separator 'Common options:'

          p.on('-b', '--bus DOMAIN|@NAME', %{
            The domain name of the bus to interact with, or a reference (`NAME`)
            to global configuration.
          }) do |v|
            config.bus = v
          end

          p.on('-t', '--token TOKEN', %{
            An API token to use when querying the bus.
          }) do |v|
            config.token = v
          end

          p.on('-v', '--verbose', %{
            Increase logging verbosity
          }) do
            config.verbose = true
          end
        end
      end

      def _description
        self.class.descr.split(/\n/).map(&:strip).reject(&:empty?).join("\n")
      end
    end
  end
end
