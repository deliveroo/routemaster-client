require 'routemaster/cli/helper'
require 'routemaster/cli/token'
require 'routemaster/cli/pub'
require 'routemaster/cli/sub'

module Routemaster
  module CLI
    class Toplevel
      SUBCOMMANDS = [
        Token::Add, Token::Del, Token::List,
        Pub,
        Sub::Add, Sub::Del, Sub::List,
      ]

      def initialize(stderr: STDERR, stdout: STDOUT)
        @stderr = stderr
        @stdout = stdout
      end

      def run(argv)
        handler = SUBCOMMANDS.find do |kls|
          argv.take(kls.prefix.length) == kls.prefix
        end

        bad_subcommand! if handler.nil?

        subargv = argv[handler.prefix.length..-1]
        handler.new(stderr: @stderr, stdout: @stdout).run(subargv)
      end

      private

      def bad_subcommand!
        log "Usage:"
        SUBCOMMANDS.each do |kls|
          log kls.syntax
          log kls.descr
        end
        raise Exit, 1
      end

      def log(message)
        @stderr.puts(message)
      end
    end
  end
end

