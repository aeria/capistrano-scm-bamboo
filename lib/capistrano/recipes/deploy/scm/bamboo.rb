require 'typhoeus'
require 'json'

require 'capistrano/recipes/deploy/scm/base'

module Capistrano
  module Deploy
    module SCM
            
      class Bamboo < Base
        def head
          "#{variable(:plan_key)}-#{variable(:build_number)}"
        end

        def query_revision(revision)
          revision
          # return revision if revision =~ /^\d+$/
          # raise "invalid revision: #{revision}"
        end

        def checkout(revision, destination)
          # TODO: graceful error handling
          response = Typhoeus::Request.get("#{repository}/result/#{variable(:plan_key)}/#{variable(:build_number)}.json?expand=artifacts", :username => variable(:scm_username), :password => variable(:scm_passphrase))
          result = JSON.parse(response.body)
          artifact = result["artifacts"]["artifact"].select { |artifact| artifact["name"] == variable(:artifact) }
          artifactUrl = artifact[0]["link"]["href"]
          
          build_actual = result["number"]
          
          %Q{TMPDIR=`mktemp -d` && cd $TMPDIR && wget -m -nH -q #{artifactUrl} && mv artifact/#{variable(:plan_key)}/shared/build-#{build_actual}/#{variable(:artifact)}/ "#{destination}" && rm -rf "$TMPDIR"}
        end

        alias_method :export, :checkout

        # def log(from, to=nil)
        #   log_build_message(from, to)
        #   log_scm_message(from, to)
        #   'true'
        # end

        def diff(from, to=nil)
          logger.info 'bamboo does not support diff'
          'true'
        end
      end
    end
  end
end
