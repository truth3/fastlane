module Fastlane
  module Actions
    module SharedValues
    end

    # Raises an exception and stop the lane execution if the repo is not on a specific branch
    class EnsureGitBranchAction < Action
      def self.run(params)
        branch = params[:branch]
        branch_expr = /#{branch}/
        if Actions.git_branch =~ branch_expr
          Helper.log.info "Git branch match `#{branch}`, all good! 💪".green
        else
          raise "Git is not on a branch matching `#{branch}`. Current branch is `#{Actions.git_branch}`! Please ensure the repo is checked out to the correct branch.".red
        end
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Raises an exception if not on a specific git branch"
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :branch,
                                       env_name: "FL_ENSURE_GIT_BRANCH_NAME",
                                       description: "The branch that should be checked for. String that can be either the full name of the branch or a regex to match",
                                       is_string: true,
                                       default_value: 'master')
        ]
      end

      def self.output
        []
      end

      def self.author
        ['dbachrach', 'Liquidsoul']
      end

      def self.is_supported?(platform)
        true
      end
    end
  end
end
