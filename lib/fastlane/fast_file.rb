module Fastlane
  class FastFile
    attr_accessor :runner

    # @return The runner which can be executed to trigger the given actions
    def initialize(path = nil)
      if (path || '').length > 0
        raise "Could not find Fastfile at path '#{path}'".red unless File.exists?path
        @path = path
        content = File.read(path)

        parse(content)
      end
    end

    def parse(data)
      @runner = Runner.new
      load_actions
      eval(data) # this is okay in this case
      return self
    end

    def lane(key, &block)
      @runner.set_block(key, block)
    end

    def before_all(&block)
      @runner.set_before_all(block)
    end

    def after_all(&block)
      @runner.set_after_all(block)
    end

    def method_missing(method_sym, *arguments, &block)
      # First, check if there is a predefined method in the actions folder
      if Fastlane::Actions.respond_to?(method_sym)
        Fastlane::Actions.method(method_sym).call(arguments)
      else
        # Method not found
        raise "Could not find method '#{method_sym}'. Use `lane :name do ... end`".red
      end
    end

    private
      def load_actions
        Dir.chdir("/Users/felixkrause/Apps/fastlane/lib") do # TODO: Remove
          Dir['fastlane/actions/*.rb'].each do |file| 
            require file
          end
        end
      end
  end
end