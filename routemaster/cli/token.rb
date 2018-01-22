require 'routemaster/cli/base'

module Routemaster
  module CLI
    module Token
      class Add < Base
        prefix %w[token add]
        syntax 'SERVICE [TOKEN]'
        descr %{
          Adds `TOKEN` to the list of API tokens permitted to use the bus API. `SERVICE`
          is a human-readable name for this token.
        }

        action do
          bad_argc! unless (1..2).include? argv.length

          service, token = argv
          puts helper.client.token_add(name: service, token: token)
        end
      end

      class Del < Base
        prefix %w[token del]
        syntax 'TOKEN'
        descr %{
          Removes `TOKEN` from permitted tokens if it exists.
        }

        action do
          bad_argc! unless argv.length == 1

          helper.client.token_del(token: argv.first)
        end
      end

      class List < Base
        prefix %w[token list]
        descr %{
          Lists currently permitted API tokens.
        }

        action do
          bad_argc! unless argv.length == 0

          token_list = helper.client.token_list

          if token_list.empty?
            puts 'No tokens have been added.'
          else
            helper.client.token_list.each do |t,n|
              puts "#{t}\t#{n}"
            end
          end
        end
      end
    end
  end
end
