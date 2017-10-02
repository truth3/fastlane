describe Fastlane do
  describe Fastlane::Setup do
    it "#files_to_copy" do
      expect(Fastlane::SetupIos.new.files_to_copy).to eq(['Deliverfile', 'deliver', 'screenshots', 'metadata'])
    end

    it "#show_infos" do
      Fastlane::SetupIos.new.show_infos
    end

    describe "Complete setup process" do
      let (:fixtures) { File.expand_path("./fastlane/spec/fixtures/setup_workspace/") }
      let (:workspace) { File.expand_path("/tmp/setup_workspace/") }
      before do
        fastlane_folder = File.join(workspace, 'fastlane')
        FileUtils.rm_rf(workspace) if File.directory? workspace
        FileUtils.cp_r(fixtures, File.expand_path('..', workspace)) # copy workspace to work on to /tmp

        allow(FastlaneCore::FastlaneFolder).to receive(:path).and_return(fastlane_folder)

        ENV['DELIVER_USER'] = 'felix@sunapps.net'
      end

      it "setup is successful and generated initial Fastfile" do
        expect(FastlaneCore::UI).to receive(:input).and_return("y") # iOS project, yeah

        require 'produce'

        app = "app"

        dev_team_id = "123123"
        app_identifier = "tools.fastlane.app"
        expect(Spaceship).to receive(:login)
        expect(Spaceship).to receive(:select_team).and_return(dev_team_id)
        expect(Spaceship::App).to receive(:find).with(app_identifier).and_return(app)

        itc_team_id = "itc_321"
        expect(Spaceship::Tunes).to receive(:login)
        expect(Spaceship::Tunes).to receive(:select_team).and_return(itc_team_id)
        expect(Spaceship::Tunes::Application).to receive(:find).with(app_identifier).and_return(app)

        expect(FastlaneCore::UI).to receive(:confirm).and_return(true)

        FastlaneCore::FastlaneFolder.create_folder!(workspace)
        Dir.chdir(workspace) do
          setup = Fastlane::SetupIos.new
          expect(setup).to receive(:enable_deliver).and_return(nil)
          allow(setup).to receive(:app_identifier).and_return(app_identifier) # to also support linux (travis)
          project = "proj"
          allow(setup).to receive(:project).and_return(project)
          allow(project).to receive(:mac?).and_return(false)
          allow(project).to receive(:schemes).and_return(["MyScheme"])
          allow(project).to receive(:default_app_identifier).and_return(app_identifier)
          allow(project).to receive(:default_app_name).and_return("Project Name")
          allow(project).to receive(:is_workspace).and_return(false)
          allow(project).to receive(:path).and_return("./path")

          expect(setup.run).to eq(true)
          expect(setup.tools).to eq({ snapshot: false, cocoapods: true, carthage: false })

          content = File.read(File.join(FastlaneCore::FastlaneFolder.path, 'Fastfile'))
          expect(content).to include "# update_fastlane"
          expect(content).to include "deliver"
          expect(content).to include "scan"
          expect(content).to include "gym(scheme: \"MyScheme\")"

          content = File.read(File.join(FastlaneCore::FastlaneFolder.path, 'Appfile'))

          expect(content).to include "app_identifier \"#{app_identifier}\""
          expect(content).to include "team_id \"#{dev_team_id}\""
          expect(content).to include "itc_team_id \"#{itc_team_id}\""
          expect(content).to include "apple_id \"y\""
        end
      end

      describe "react-native" do
        it "tells the user to naviate into the subfolder to run `fastlane init`" do
          expect do
            expect(Fastlane::SetupIos).to receive(:project_uses_react_native?).with(path: "./ios").and_return(true)

            setup = Fastlane::Setup.new
            setup.run
          end.to raise_error("Please navigate to the platform subfolder and run `fastlane init` again")
        end

        it "tells the user to set a custom app identifier if none is set yet" do
          expect do
            setup = Fastlane::SetupIos.new

            expect(Fastlane::SetupIos).to receive(:project_uses_react_native?).with(no_args).and_return(true)
            expect(setup).to receive(:setup_project).and_return(nil)

            setup.run
          end.to raise_error("Could not detect bundle identifier of your react-native app. Make sure to open the Xcode project and update the bundle identifier in the `General` section of your project settings. Restart `fastlane init` once you're done!")
        end
      end

      after do
        ENV.delete('DELIVER_USER')
      end
    end
  end
end
