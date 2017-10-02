module Fastlane
  module Helper
    module PluginScoresHelper
      require 'faraday'

      class FastlanePluginRating
        attr_accessor :key
        attr_accessor :description
        attr_accessor :value

        def initialize(key: nil, description: nil, value: nil)
          self.key = key
          self.description = description
          self.value = value
        end
      end

      class FastlanePluginScore
        attr_accessor :name
        attr_accessor :downloads
        attr_accessor :info
        attr_accessor :homepage
        attr_accessor :raw_hash

        attr_accessor :data

        def initialize(hash)
          if ENV["GITHUB_USER_NAME"].to_s.length == 0 || ENV["GITHUB_API_TOKEN"].to_s.length == 0
            raise "Missing ENV variables GITHUB_USER_NAME and/or GITHUB_API_TOKEN"
          end

          self.name = hash["name"]
          self.downloads = hash["downloads"]
          self.info = hash["info"]
          self.homepage = hash["homepage_uri"] || hash["documentation_uri"]
          self.raw_hash = hash

          has_github_page = self.homepage.to_s.include?("https://github.com") # Here we can add non GitHub support one day

          self.data = {
            has_homepage: self.homepage.to_s.length > 5,
            has_info: self.info.to_s.length > 5,
            downloads: self.downloads,
            has_github_page: has_github_page,
            has_mit_license: includes_license?("MIT"),
            has_gnu_license: includes_license?("GNU") || includes_license?("GPL"),
            major_release: Gem::Version.new(hash["version"]) >= Gem::Version.new("1.0.0")
          }

          if has_github_page
            self.append_git_data
            self.append_github_data
          end

          self.data[:overall_score] = 0
          self.data[:ratings] = self.ratings.collect do |current_rating|
            [
              current_rating.key,
              current_rating.value
            ]
          end.to_h

          self.ratings.each do |current_rating|
            self.data[:overall_score] += current_rating.value
          end
        end

        def ratings
          [
            FastlanePluginRating.new(key: :contributors,
                             description: "The more contributors a project has, the more likely it is it stays alive",
                                   value: self.data[:github_contributors].to_i * 6),
            FastlanePluginRating.new(key: :subscribers,
                             description: "More subscribers = more popular project",
                                   value: self.data[:github_subscribers].to_i * 3),
            FastlanePluginRating.new(key: :stars,
                             description: "More stars = more popular project",
                                   value: self.data[:github_stars].to_i),
            FastlanePluginRating.new(key: :forks,
                             description: "More forks = more people seem to use/modify this project",
                                   value: self.data[:github_forks].to_i * 5),
            FastlanePluginRating.new(key: :has_mit_license,
                             description: "fastlane is MIT licensed, it's good to have plugins use MIT too",
                                   value: (self.data[:has_mit_license] ? 20 : -50)),
            FastlanePluginRating.new(key: :readme_score,
                             description: "How well is the README of the document written",
                                   value: self.data[:readme_score].to_i / 2),
            FastlanePluginRating.new(key: :age,
                             description: "Project that have been around for longer tend to be more stable",
                                   value: self.data[:age_in_days].to_i / 60),
            FastlanePluginRating.new(key: :major_release,
                             description: "Post 1.0 releases are great",
                                   value: (self.data[:major_release] ? 30 : 0)),
            FastlanePluginRating.new(key: :github_issues,
                             description: "Lots of open issues are not a good sign usually, unless the project is really popular",
                                   value: (self.data[:github_issues].to_i * -1)),
            FastlanePluginRating.new(key: :downloads,
                             description: "More downloads = more users have been using the plugin for a while",
                                   value: (self.data[:downloads].to_i / 250)),
            FastlanePluginRating.new(key: :tests,
                             description: "The more tests a plugin has, the better",
                                   value: [self.data[:tests].to_i * 3, 80].min)
          ]
        end

        # What colors should the overall score be printed in
        def color_to_use
          case self.data[:overall_score]
          when -1000...40
            'ff6666'
          when 40...100
            '558000'
          when 100...250
            '63b319'
          when 250...10_000
            '72CC1D'
          else
            '558000' # this shouldn't happen
          end
        end

        def includes_license?(license)
          # e.g. "licenses"=>["MIT"],
          self.raw_hash["licenses"].any? { |l| l.include?(license) }
        end

        # Everything that needs to be fetched from the content of the Git repo
        def append_git_data
          Dir.mktmpdir("fastlane-plugin") do |tmp|
            clone_folder = File.join(tmp, self.name)
            `git clone '#{self.homepage}' '#{clone_folder}'`

            break unless File.directory?(clone_folder)

            Dir.chdir(clone_folder) do
              # Taken from https://github.com/CocoaPods/cocoadocs.org/blob/master/classes/stats_generator.rb
              self.data[:initial_commit] = DateTime.parse(`git rev-list --all|tail -n1|xargs git show|grep -v diff|head -n3|tail -1|cut -f2-8 -d' '`.strip).to_date
              self.data[:age_in_days] = (DateTime.now - self.data[:initial_commit]).to_i

              readme_score = 100
              if File.exist?("README.md")
                readme_content = File.read("README.md").downcase
                readme_score -= 50 if readme_content.include?("note to author")
                readme_score -= 50 if readme_content.include?("todo")
              else
                readme_score = 0
              end
              self.data[:readme_score] = readme_score

              # Detect how many tests this plugin has
              tests_count = 0
              Dir["spec/**/*_spec.rb"].each do |spec_file|
                # poor person's way to detect the number of tests, good enough to get a sense
                tests_count += File.read(spec_file).scan(/ it /).count
              end
              self.data[:tests] = tests_count
            end
          end
        end

        # Everything from the GitHub API (e.g. open issues and stars)
        def append_github_data
          # e.g. https://api.github.com/repos/fastlane/fastlane
          url = self.homepage.gsub("github.com/", "api.github.com/repos/")
          url = url[0..-2] if url.end_with?("/") # what is this, 2001? We got to remove the trailing `/` otherwise Github will fail
          puts "Fetching #{url}"
          conn = Faraday.new(url: url) do |builder|
            # The order below IS important
            # See bug here https://github.com/lostisland/faraday_middleware/issues/105
            builder.use FaradayMiddleware::FollowRedirects
            builder.adapter Faraday.default_adapter
          end
          conn.basic_auth(ENV["GITHUB_USER_NAME"], ENV["GITHUB_API_TOKEN"])
          response = conn.get('')
          repo_details = JSON.parse(response.body)

          url += "/stats/contributors"
          puts "Fetching #{url}"
          conn = Faraday.new(url: url) do |builder|
            # The order below IS important
            # See bug here https://github.com/lostisland/faraday_middleware/issues/105
            builder.use FaradayMiddleware::FollowRedirects
            builder.adapter Faraday.default_adapter
          end

          conn.basic_auth(ENV["GITHUB_USER_NAME"], ENV["GITHUB_API_TOKEN"])
          response = conn.get('')
          contributor_details = JSON.parse(response.body)

          self.data[:github_stars] = repo_details["stargazers_count"].to_i
          self.data[:github_subscribers] = repo_details["subscribers_count"].to_i
          self.data[:github_issues] = repo_details["open_issues_count"].to_i
          self.data[:github_forks] = repo_details["forks_count"].to_i
          self.data[:github_contributors] = contributor_details.count
        rescue => ex
          puts "error fetching #{self}"
          puts self.homepage
          puts "Chances are high you exceeded the GitHub API limit"
          puts ex
          puts ex.backtrace
          raise ex
        end
      end
    end
  end
end
