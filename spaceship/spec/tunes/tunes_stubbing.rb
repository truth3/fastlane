# rubocop:disable Metrics/ClassLength
class TunesStubbing
  class << self
    def itc_read_fixture_file(filename)
      File.read(File.join('spaceship', 'spec', 'tunes', 'fixtures', filename))
    end

    # Necessary, as we're now running this in a different context
    def stub_request(*args)
      WebMock::API.stub_request(*args)
    end

    def itc_stub_login
      # Retrieving the current login URL
      itc_service_key_path = File.expand_path("~/Library/Caches/spaceship_itc_service_key.txt")
      File.delete(itc_service_key_path) if File.exist?(itc_service_key_path)

      stub_request(:get, 'https://itunesconnect.apple.com/itc/static-resources/controllers/login_cntrl.js').
        to_return(status: 200, body: itc_read_fixture_file('login_cntrl.js'))
      stub_request(:get, "https://itunesconnect.apple.com/WebObjects/iTunesConnect.woa").
        to_return(status: 200, body: "")
      stub_request(:get, "https://itunesconnect.apple.com/WebObjects/iTunesConnect.woa/wa").
        to_return(status: 200, body: "")
      stub_request(:get, "https://olympus.itunes.apple.com/v1/session").
        to_return(status: 200, body: "") # we don't actually care about the body
      stub_request(:get, "https://olympus.itunes.apple.com/v1/app/config?hostname=itunesconnect.apple.com").
        to_return(status: 200, body: { authServiceKey: 'e0abc' }.to_json, headers: { 'Content-Type' => 'application/json' })

      # Actual login
      stub_request(:post, "https://idmsa.apple.com/appleauth/auth/signin").
        with(body: { "accountName" => "spaceship@krausefx.com", "password" => "so_secret", "rememberMe" => true }.to_json).
        to_return(status: 200, body: '{}', headers: { 'Set-Cookie' => "myacinfo=abcdef;" })

      # Failed login attempts
      stub_request(:post, "https://idmsa.apple.com/appleauth/auth/signin").
        with(body: { "accountName" => "bad-username", "password" => "bad-password", "rememberMe" => true }.to_json).
        to_return(status: 401, body: '{}', headers: { 'Set-Cookie' => 'session=invalid' })
    end

    def itc_stub_applications
      stub_request(:get, "https://itunesconnect.apple.com/WebObjects/iTunesConnect.woa/ra/apps/manageyourapps/summary/v2").
        to_return(status: 200, body: itc_read_fixture_file('app_summary.json'), headers: { 'Content-Type' => 'application/json' })

      # Create Version stubbing
      stub_request(:post, "https://itunesconnect.apple.com/WebObjects/iTunesConnect.woa/ra/apps/version/create/1013943394").
        with(body: "{\"version\":\"0.1\"}").
        to_return(status: 200, body: itc_read_fixture_file('create_version_success.json'), headers: { 'Content-Type' => 'application/json' })

      # Create Application
      # Pre-Fill request
      stub_request(:get, "https://itunesconnect.apple.com/WebObjects/iTunesConnect.woa/ra/apps/create/v2/?platformString=ios").
        to_return(status: 200, body: itc_read_fixture_file('create_application_prefill_request.json'), headers: { 'Content-Type' => 'application/json' })

      # Actual success request
      stub_request(:post, "https://itunesconnect.apple.com/WebObjects/iTunesConnect.woa/ra/apps/create/v2").
        to_return(status: 200, body: itc_read_fixture_file('create_application_success.json'), headers: { 'Content-Type' => 'application/json' })

      # Overview of application to get the versions
      stub_request(:get, "https://itunesconnect.apple.com/WebObjects/iTunesConnect.woa/ra/apps/1013943394/overview").
        to_return(status: 200, body: itc_read_fixture_file('app_overview.json'), headers: { 'Content-Type' => 'application/json' })

      stub_request(:get, "https://itunesconnect.apple.com/WebObjects/iTunesConnect.woa/ra/apps/898536088/overview").
        to_return(status: 200, body: itc_read_fixture_file('app_overview.json'), headers: { 'Content-Type' => 'application/json' })

      stub_request(:get, "https://itunesconnect.apple.com/WebObjects/iTunesConnect.woa/ra/apps/1000000000/overview").
        to_return(status: 200, body: itc_read_fixture_file('app_overview_stuckinprepare.json'), headers: { 'Content-Type' => 'application/json' })

      # App Details
      stub_request(:get, "https://itunesconnect.apple.com/WebObjects/iTunesConnect.woa/ra/apps/898536088/details").
        to_return(status: 200, body: itc_read_fixture_file('app_details.json'), headers: { 'Content-Type' => 'application/json' })

      # Versions History
      stub_request(:get, "https://itunesconnect.apple.com/WebObjects/iTunesConnect.woa/ra/apps/898536088/stateHistory?platform=ios").
        to_return(status: 200, body: itc_read_fixture_file('app_versions_history.json'), headers: { 'Content-Type' => 'application/json' })

      stub_request(:get, "https://itunesconnect.apple.com/WebObjects/iTunesConnect.woa/ra/apps/898536088/versions/814624685/stateHistory?platform=ios").
        to_return(status: 200, body: itc_read_fixture_file('app_version_states_history.json'), headers: { 'Content-Type' => 'application/json' })
    end

    def itc_stub_ratings
      stub_request(:get, "https://itunesconnect.apple.com/WebObjects/iTunesConnect.woa/ra/apps/898536088/platforms/ios/reviews/summary").
        to_return(status: 200, body: itc_read_fixture_file('ratings.json'), headers: { 'Content-Type' => 'application/json' })

      stub_request(:get, "https://itunesconnect.apple.com/WebObjects/iTunesConnect.woa/ra/apps/898536088/platforms/ios/reviews/summary?storefront=US").
        to_return(status: 200, body: itc_read_fixture_file('ratings_US.json'), headers: { 'Content-Type' => 'application/json' })

      stub_request(:get, "https://itunesconnect.apple.com/WebObjects/iTunesConnect.woa/ra/apps/898536088/platforms/ios/reviews?index=0&sort=REVIEW_SORT_ORDER_MOST_RECENT&storefront=US").
        to_return(status: 200, body: itc_read_fixture_file('review_by_storefront.json'), headers: { 'Content-Type' => 'application/json' })
    end

    def itc_stub_build_details
      stub_request(:get, "https://itunesconnect.apple.com/WebObjects/iTunesConnect.woa/ra/apps/898536088/buildHistory?platform=ios").
        to_return(status: 200, body: itc_read_fixture_file('build_history.json'), headers: { 'Content-Type' => 'application/json' })
      stub_request(:get, "https://itunesconnect.apple.com/WebObjects/iTunesConnect.woa/ra/apps/898536088/trains/2.0.1/buildHistory?platform=ios").
        to_return(status: 200, body: itc_read_fixture_file('build_history_for_train.json'), headers: { 'Content-Type' => 'application/json' })
      stub_request(:get, "https://itunesconnect.apple.com/WebObjects/iTunesConnect.woa/ra/apps/898536088/platforms/ios/trains/2.0.1/builds/4/details").
        to_return(status: 200, body: itc_read_fixture_file('build_details.json'), headers: { 'Content-Type' => 'application/json' })
    end

    def itc_stub_candiate_builds
      stub_request(:get, "https://itunesconnect.apple.com/WebObjects/iTunesConnect.woa/ra/apps/898536088/versions/812106519/candidateBuilds").
        to_return(status: 200, body: itc_read_fixture_file('candiate_builds.json'), headers: { 'Content-Type' => 'application/json' })
    end

    def itc_stub_applications_first_create
      # Create First Application
      # Pre-Fill request
      stub_request(:get, "https://itunesconnect.apple.com/WebObjects/iTunesConnect.woa/ra/apps/create/v2/?platformString=ios").
        to_return(status: 200, body: itc_read_fixture_file('create_application_prefill_first_request.json'), headers: { 'Content-Type' => 'application/json' })
    end

    def itc_stub_applications_broken_first_create
      stub_request(:post, "https://itunesconnect.apple.com/WebObjects/iTunesConnect.woa/ra/apps/create/v2").
        to_return(status: 200, body: itc_read_fixture_file('create_application_first_broken.json'), headers: { 'Content-Type' => 'application/json' })
    end

    def itc_stub_broken_create
      stub_request(:post, "https://itunesconnect.apple.com/WebObjects/iTunesConnect.woa/ra/apps/create/v2").
        to_return(status: 200, body: itc_read_fixture_file('create_application_broken.json'), headers: { 'Content-Type' => 'application/json' })
    end

    def itc_stub_broken_create_wildcard
      stub_request(:post, "https://itunesconnect.apple.com/WebObjects/iTunesConnect.woa/ra/apps/create/v2").
        to_return(status: 200, body: itc_read_fixture_file('create_application_wildcard_broken.json'), headers: { 'Content-Type' => 'application/json' })
    end

    def itc_stub_app_versions
      # Receiving app version
      stub_request(:get, "https://itunesconnect.apple.com/WebObjects/iTunesConnect.woa/ra/apps/898536088/platforms/ios/versions/813314674").
        to_return(status: 200, body: itc_read_fixture_file('app_version.json'), headers: { 'Content-Type' => 'application/json' })
      stub_request(:get, "https://itunesconnect.apple.com/WebObjects/iTunesConnect.woa/ra/apps/898536088/platforms/ios/versions/113314675").
        to_return(status: 200, body: itc_read_fixture_file('app_version.json'), headers: { 'Content-Type' => 'application/json' })
      stub_request(:get, "https://itunesconnect.apple.com/WebObjects/iTunesConnect.woa/ra/apps/1000000000/platforms/ios/versions/800000000").
        to_return(status: 200, body: itc_read_fixture_file('app_version.json'), headers: { 'Content-Type' => 'application/json' })
    end

    def itc_stub_app_submissions
      # Start app submission
      stub_request(:get, "https://itunesconnect.apple.com/WebObjects/iTunesConnect.woa/ra/apps/898536088/versions/812106519/submit/summary").
        to_return(status: 200, body: itc_read_fixture_file('app_submission/start_success.json'), headers: { 'Content-Type' => 'application/json' })

      # Complete app submission
      stub_request(:post, "https://itunesconnect.apple.com/WebObjects/iTunesConnect.woa/ra/apps/898536088/versions/812106519/submit/complete").
        to_return(status: 200, body: itc_read_fixture_file('app_submission/complete_success.json'), headers: { 'Content-Type' => 'application/json' })
    end

    def itc_stub_app_submissions_already_submitted
      # Start app submission
      stub_request(:get, "https://itunesconnect.apple.com/WebObjects/iTunesConnect.woa/ra/apps/898536088/versions/812106519/submit/summary").
        to_return(status: 200, body: itc_read_fixture_file('app_submission/start_success.json'), headers: { 'Content-Type' => 'application/json' })

      # Complete app submission
      stub_request(:post, "https://itunesconnect.apple.com/WebObjects/iTunesConnect.woa/ra/apps/898536088/versions/812106519/submit/complete").
        to_return(status: 200, body: itc_read_fixture_file('app_submission/complete_failed.json'), headers: { 'Content-Type' => 'application/json' })
    end

    def itc_stub_app_submissions_invalid
      # Start app submission
      stub_request(:get, "https://itunesconnect.apple.com/WebObjects/iTunesConnect.woa/ra/apps/898536088/versions/812106519/submit/summary").
        to_return(status: 200, body: itc_read_fixture_file('app_submission/start_failed.json'), headers: { 'Content-Type' => 'application/json' })
    end

    def itc_stub_resolution_center
      # Called from the specs to simulate invalid server responses
      stub_request(:get, "https://itunesconnect.apple.com/WebObjects/iTunesConnect.woa/ra/apps/898536088/resolutionCenter?v=latest").
        to_return(status: 200, body: itc_read_fixture_file('app_resolution_center.json'), headers: { 'Content-Type' => 'application/json' })

      stub_request(:get, "https://itunesconnect.apple.com/WebObjects/iTunesConnect.woa/ra/apps/898536088/platforms/ios/resolutionCenter?v=latest").
        to_return(status: 200, body: itc_read_fixture_file('app_resolution_center.json'), headers: { 'Content-Type' => 'application/json' })
    end

    def itc_stub_build_trains
      %w(internal external).each do |type|
        stub_request(:get, "https://itunesconnect.apple.com/WebObjects/iTunesConnect.woa/ra/apps/898536088/trains/?platform=ios&testingType=#{type}").
          to_return(status: 200, body: itc_read_fixture_file('build_trains.json'), headers: { 'Content-Type' => 'application/json' })

        stub_request(:get, "https://itunesconnect.apple.com/WebObjects/iTunesConnect.woa/ra/apps/898536088/trains/?platform=appletvos&testingType=#{type}").
          to_return(status: 200, body: itc_read_fixture_file('build_trains.json'), headers: { 'Content-Type' => 'application/json' })

        stub_request(:get, "https://itunesconnect.apple.com/WebObjects/iTunesConnect.woa/ra/apps/898536088/trains/?testingType=#{type}").
          to_return(status: 200, body: itc_read_fixture_file('build_trains.json'), headers: { 'Content-Type' => 'application/json' })

        # Update build trains
        stub_request(:post, "https://itunesconnect.apple.com/WebObjects/iTunesConnect.woa/ra/apps/898536088/testingTypes/#{type}/trains/").
          to_return(status: 200, body: itc_read_fixture_file('build_trains.json'), headers: { 'Content-Type' => 'application/json' })
      end
    end

    def itc_stub_testers
      stub_request(:get, "https://itunesconnect.apple.com/WebObjects/iTunesConnect.woa/ra/users/pre/int").
        to_return(status: 200, body: itc_read_fixture_file('testers/get_internal.json'), headers: { 'Content-Type' => 'application/json' })
      stub_request(:get, "https://itunesconnect.apple.com/WebObjects/iTunesConnect.woa/ra/users/pre/ext").
        to_return(status: 200, body: itc_read_fixture_file('testers/get_external.json'), headers: { 'Content-Type' => 'application/json' })
      stub_request(:get, "https://itunesconnect.apple.com/WebObjects/iTunesConnect.woa/ra/user/internalTesters/898536088/").
        to_return(status: 200, body: itc_read_fixture_file('testers/existing_internal_testers.json'), headers: { 'Content-Type' => 'application/json' })

      # Creating new testers is stubbed in `testers_spec.rb`
    end

    def itc_stub_testflight
      %w(appletvos ios).each do |type|
        # Test information
        stub_request(:get, "https://itunesconnect.apple.com/WebObjects/iTunesConnect.woa/ra/apps/898536088/platforms/#{type}/trains/1.0/builds/10/testInformation").
          to_return(status: 200, body: itc_read_fixture_file("testflight_build_info_#{type}.json"), headers: { 'Content-Type' => 'application/json' })

        # Reject review
        stub_request(:post, "https://itunesconnect.apple.com/WebObjects/iTunesConnect.woa/ra/apps/898536088/platforms/#{type}/trains/1.0/builds/10/reject").
          with(body: "{}").
          to_return(status: 200, body: "{}", headers: { 'Content-Type' => 'application/json' })

        # Submission
        stub_request(:post, "https://itunesconnect.apple.com/WebObjects/iTunesConnect.woa/ra/apps/898536088/platforms/#{type}/trains/1.0/builds/10/review/submit").
          to_return(status: 200, body: itc_read_fixture_file("testflight_submission_submit_#{type}.json"), headers: { 'Content-Type' => 'application/json' })
      end
    end

    def itc_stub_resolution_center_valid
      # Called from the specs to simulate valid server responses
      stub_request(:get, "https://itunesconnect.apple.com/WebObjects/iTunesConnect.woa/ra/apps/898536088/resolutionCenter?v=latest").
        to_return(status: 200, body: itc_read_fixture_file('app_resolution_center_valid.json'), headers: { 'Content-Type' => 'application/json' })
      stub_request(:get, "https://itunesconnect.apple.com/WebObjects/iTunesConnect.woa/ra/apps/898536088/platforms/ios/resolutionCenter?v=latest").
        to_return(status: 200, body: itc_read_fixture_file('app_resolution_center_valid.json'), headers: { 'Content-Type' => 'application/json' })
    end

    def itc_stub_invalid_update
      # Called from the specs to simulate invalid server responses
      stub_request(:post, "https://itunesconnect.apple.com/WebObjects/iTunesConnect.woa/ra/apps/898536088/platforms/ios/versions/812106519").
        to_return(status: 200, body: itc_read_fixture_file('update_app_version_failed.json'), headers: { 'Content-Type' => 'application/json' })
    end

    def itc_stub_valid_update
      # Called from the specs to simulate valid server responses
      stub_request(:post, "https://itunesconnect.apple.com/WebObjects/iTunesConnect.woa/ra/apps/898536088/platforms/ios/versions/812106519").
        to_return(status: 200, body: itc_read_fixture_file("update_app_version_success.json"),
                  headers: { "Content-Type" => "application/json" })
    end

    def itc_stub_valid_version_update_with_autorelease_and_release_on_datetime
      # Called from the specs to simulate valid server responses
      stub_request(:post, "https://itunesconnect.apple.com/WebObjects/iTunesConnect.woa/ra/apps/898536088/platforms/ios/versions/812106519").
        to_return(status: 200, body: itc_read_fixture_file("update_app_version_with_autorelease_overwrite_success.json"),
                  headers: { "Content-Type" => "application/json" })
    end

    def itc_stub_app_version_ref
      stub_request(:get, "https://itunesconnect.apple.com/WebObjects/iTunesConnect.woa/ra/apps/version/ref").
        to_return(status: 200, body: itc_read_fixture_file("app_version_ref.json"),
                  headers: { "Content-Type" => "application/json" })
    end

    def itc_stub_user_detail
      stub_request(:get, "https://itunesconnect.apple.com/WebObjects/iTunesConnect.woa/ra/user/detail").
        to_return(status: 200, body: itc_read_fixture_file("user_detail.json"),
                  headers: { "Content-Type" => "application/json" })
    end

    def itc_stub_sandbox_testers
      stub_request(:get, "https://itunesconnect.apple.com/WebObjects/iTunesConnect.woa/ra/users/iap").
        to_return(status: 200, body: itc_read_fixture_file("sandbox_testers.json"),
                  headers: { "Content-Type" => "application/json" })
    end

    def itc_stub_create_sandbox_tester
      stub_request(:post, "https://itunesconnect.apple.com/WebObjects/iTunesConnect.woa/ra/users/iap/add").
        with(body: JSON.parse(itc_read_fixture_file("create_sandbox_tester_payload.json"))).
        to_return(status: 200, body: itc_read_fixture_file("create_sandbox_tester.json"),
                  headers: { "Content-Type" => "application/json" })
    end

    def itc_stub_delete_sandbox_tester
      body = JSON.parse(itc_read_fixture_file("delete_sandbox_tester_payload.json"))
      stub_request(:post, "https://itunesconnect.apple.com/WebObjects/iTunesConnect.woa/ra/users/iap/delete").
        with(body: JSON.parse(itc_read_fixture_file("delete_sandbox_tester_payload.json")).to_json).
        to_return(status: 200, body: itc_read_fixture_file("delete_sandbox_tester.json"),
                  headers: { "Content-Type" => "application/json" })
    end

    def itc_stub_pricing_tiers
      stub_request(:get, "https://itunesconnect.apple.com/WebObjects/iTunesConnect.woa/ra/apps/pricing/matrix").
        to_return(status: 200, body: itc_read_fixture_file("pricing_tiers.json"),
                  headers: { "Content-Type" => "application/json" })
    end

    def itc_stub_release_to_store
      stub_request(:post, "https://itunesconnect.apple.com/WebObjects/iTunesConnect.woa/ra/apps/898536088/versions/812106519/releaseToStore").
        with(body: "898536088").
        to_return(status: 200, body: itc_read_fixture_file("update_app_version_success.json"),
                  headers: { "Content-Type" => "application/json" })
    end

    def itc_stub_promocodes
      stub_request(:get, "https://itunesconnect.apple.com/WebObjects/iTunesConnect.woa/ra/apps/898536088/promocodes/versions").
        to_return(status: 200, body: itc_read_fixture_file("promocodes.json"),
                  headers: { "Content-Type" => "application/json" })
    end

    def itc_stub_generate_promocodes
      stub_request(:post, "https://itunesconnect.apple.com/WebObjects/iTunesConnect.woa/ra/apps/898536088/promocodes/versions/812106519").
        to_return(status: 200, body: itc_read_fixture_file("promocodes_generated.json"),
                  headers: { "Content-Type" => "application/json" })
    end

    def itc_stub_promocodes_history
      stub_request(:get, "https://itunesconnect.apple.com/WebObjects/iTunesConnect.woa/ra/apps/898536088/promocodes/history").
        to_return(status: 200, body: itc_read_fixture_file("promocodes_history.json"),
                  headers: { "Content-Type" => "application/json" })
    end

    def itc_stub_iap
      # pricing goal calculator
      stub_request(:get, "https://itunesconnect.apple.com/WebObjects/iTunesConnect.woa/ra/apps/898536088/iaps/1195137656/pricing/equalize/EUR/1").
        to_return(status: 200, body: itc_read_fixture_file("iap_price_goal_calc.json"),
                 headers: { "Content-Type" => "application/json" })
      # delete iap
      stub_request(:delete, "https://itunesconnect.apple.com/WebObjects/iTunesConnect.woa/ra/apps/898536088/iaps/1194457865").
        to_return(status: 200, body: "", headers: {})
      # create consumable iap
      stub_request(:post, "https://itunesconnect.apple.com/WebObjects/iTunesConnect.woa/ra/apps/898536088/iaps").
        with(body: itc_read_fixture_file("iap_create.json")).
        to_return(status: 200, body: itc_read_fixture_file("iap_detail.json"),
                 headers: { "Content-Type" => "application/json" })

      # iap consumable template
      stub_request(:get, "https://itunesconnect.apple.com/WebObjects/iTunesConnect.woa/ra/apps/898536088/iaps/consumable/template").
        to_return(status: 200, body: itc_read_fixture_file("iap_consumable_template.json"),
                 headers: { "Content-Type" => "application/json" })
      # iap edit family
      stub_request(:put, "https://itunesconnect.apple.com/WebObjects/iTunesConnect.woa/ra/apps/898536088/iaps/family/20373395/").
        with(body: itc_read_fixture_file("iap_family_edit_versions.json")).
        to_return(status: 200, body: itc_read_fixture_file("iap_family_detail.json"),
                    headers: { "Content-Type" => "application/json" })

      # iap edit family
      stub_request(:put, "https://itunesconnect.apple.com/WebObjects/iTunesConnect.woa/ra/apps/898536088/iaps/family/20373395/").
        with(body: itc_read_fixture_file("iap_family_edit.json")).
        to_return(status: 200, body: itc_read_fixture_file("iap_family_detail.json"),
                headers: { "Content-Type" => "application/json" })

      # iap family detail
      stub_request(:get, "https://itunesconnect.apple.com/WebObjects/iTunesConnect.woa/ra/apps/898536088/iaps/family/20372345").
        to_return(status: 200, body: itc_read_fixture_file("iap_family_detail.json"),
                    headers: { "Content-Type" => "application/json" })
      # create IAP family
      stub_request(:post, "https://itunesconnect.apple.com/WebObjects/iTunesConnect.woa/ra/apps/898536088/iaps/family/").
        with(body: JSON.parse(itc_read_fixture_file("iap_family_create.json"))).
        to_return(status: 200, body: itc_read_fixture_file("iap_family_create_success.json"), headers: { "Content-Type" => "application/json" })

      # load IAP Family Template
      stub_request(:get, "https://itunesconnect.apple.com/WebObjects/iTunesConnect.woa/ra/apps/898536088/iaps/family/template").
        to_return(status: 200, body: itc_read_fixture_file("iap_family_template.json"),
                 headers: { "Content-Type" => "application/json" })

      # update IAP
      stub_request(:put, "https://itunesconnect.apple.com/WebObjects/iTunesConnect.woa/ra/apps/898536088/iaps/1195137656").
        with(body: JSON.parse(itc_read_fixture_file("iap_update.json"))).
        to_return(status: 200, body: itc_read_fixture_file("iap_detail.json"),
                   headers: { "Content-Type" => "application/json" })

      # iap details
      stub_request(:get, "https://itunesconnect.apple.com/WebObjects/iTunesConnect.woa/ra/apps/898536088/iaps/1194457865").
        to_return(status: 200, body: itc_read_fixture_file("iap_detail.json"),
                headers: { "Content-Type" => "application/json" })

      # list families
      stub_request(:get, "https://itunesconnect.apple.com/WebObjects/iTunesConnect.woa/ra/apps/898536088/iaps/families").
        to_return(status: 200, body: itc_read_fixture_file("iap_families.json"),
                headers: { "Content-Type" => "application/json" })

      # list iaps
      stub_request(:get, "https://itunesconnect.apple.com/WebObjects/iTunesConnect.woa/ra/apps/898536088/iaps").
        to_return(status: 200, body: itc_read_fixture_file("iap_list.json"),
                headers: { "Content-Type" => "application/json" })

      # subscription pricing tiers
      stub_request(:get, "https://itunesconnect.apple.com/WebObjects/iTunesConnect.woa/ra/apps/898536088/iaps/pricing/matrix/recurring").
        to_return(status: 200, body: itc_read_fixture_file("iap_pricing_tiers.json"),
                  headers: { "Content-Type" => "application/json" })
    end

    def itc_stub_reject_version_success
      stub_request(:post, "https://itunesconnect.apple.com/WebObjects/iTunesConnect.woa/ra/apps/898536088/versions/812106519/reject").
        to_return(status: 200, body: itc_read_fixture_file("reject_app_version_success.json"),
                  headers: { "Content-Type" => "application/json" })
    end

    def itc_stub_supported_countries
      stub_request(:get, "https://itunesconnect.apple.com/WebObjects/iTunesConnect.woa/ra/apps/pricing/supportedCountries").
        to_return(status: 200, body: itc_read_fixture_file(File.join('supported_countries.json')),
                  headers: { 'Content-Type' => 'application/json' })
    end

    def itc_stub_app_pricing_intervals
      stub_request(:get, "https://itunesconnect.apple.com/WebObjects/iTunesConnect.woa/ra/apps/898536088/pricing/intervals").
        to_return(status: 200, body: itc_read_fixture_file(File.join('app_pricing_intervals.json')),
                  headers: { 'Content-Type' => 'application/json' })
    end

    def itc_stub_app_add_territory
      stub_request(:post, "https://itunesconnect.apple.com/WebObjects/iTunesConnect.woa/ra/apps/898536088/pricing/intervals").
        with(body: JSON.parse(itc_read_fixture_file(File.join('availability', 'add_request.json'))).to_json).
        to_return(status: 200, body: itc_read_fixture_file(File.join('availability', 'add_response.json')),
                  headers: { 'Content-Type' => 'application/json' })
    end

    def itc_stub_app_remove_territory
      stub_request(:post, "https://itunesconnect.apple.com/WebObjects/iTunesConnect.woa/ra/apps/898536088/pricing/intervals").
        with(body: JSON.parse(itc_read_fixture_file(File.join('availability', 'remove_request.json'))).to_json).
        to_return(status: 200, body: itc_read_fixture_file(File.join('availability', 'remove_response.json')),
                  headers: { 'Content-Type' => 'application/json' })
    end

    def itc_stub_app_uninclude_future_territories
      stub_request(:post, "https://itunesconnect.apple.com/WebObjects/iTunesConnect.woa/ra/apps/898536088/pricing/intervals").
        with(body: JSON.parse(itc_read_fixture_file(File.join('availability', 'uninclude_all_future_territories_request.json'))).to_json).
        to_return(status: 200, body: itc_read_fixture_file(File.join('availability', 'uninclude_all_future_territories_response.json')),
                  headers: { 'Content-Type' => 'application/json' })
    end

    def itc_stub_members
      # resend notification
      stub_request(:post, "https://itunesconnect.apple.com/WebObjects/iTunesConnect.woa/ra/users/itc/helmut@januschka.com/resendInvitation").
        to_return(status: 200, body: "", headers: {})

      # create member default (admin, all-apps)
      stub_request(:post, "https://itunesconnect.apple.com/WebObjects/iTunesConnect.woa/ra/users/itc/create").
        with(body: JSON.parse(itc_read_fixture_file("member_create.json"))).
        to_return(status: 200, body: "", headers: {})

      # create member role: developer, apps: all
      stub_request(:post, "https://itunesconnect.apple.com/WebObjects/iTunesConnect.woa/ra/users/itc/create").
        with(body: JSON.parse(itc_read_fixture_file("member_create_developer.json"))).
        to_return(status: 200, body: "", headers: {})

      # create member role: appmanager, apps: 12345
      stub_request(:post, "https://itunesconnect.apple.com/WebObjects/iTunesConnect.woa/ra/users/itc/create").
        with(body: JSON.parse(itc_read_fixture_file("member_create_appmanager_single_app.json"))).
        to_return(status: 200, body: "", headers: {})

      # member template
      stub_request(:get, "https://itunesconnect.apple.com/WebObjects/iTunesConnect.woa/ra/users/itc/create").
        to_return(status: 200, body: itc_read_fixture_file(File.join('member_template.json')),
                  headers: { "Content-Type" => "application/json" })

      # read member roles default (admin, all-apps)
      stub_request(:get, "https://itunesconnect.apple.com/WebObjects/iTunesConnect.woa/ra/users/itc/283226505/roles").
        to_return(status: 200, body: itc_read_fixture_file(File.join('member_read_roles.json')),
                  headers: { "Content-Type" => "application/json" })

      # update member default (admin, all-apps)
      stub_request(:post, "https://itunesconnect.apple.com/WebObjects/iTunesConnect.woa/ra/users/itc/283226505/roles").
        with(body: JSON.parse(itc_read_fixture_file("member_update_roles.json"))).
        to_return(status: 200, body: "", headers: {})

      # read member roles before role: developer, apps: all
      stub_request(:get, "https://itunesconnect.apple.com/WebObjects/iTunesConnect.woa/ra/users/itc/10795390202/roles").
        to_return(status: 200, body: itc_read_fixture_file(File.join('member_read_roles_before_developer.json')),
                  headers: { "Content-Type" => "application/json" })

      # update member role: developer, apps: all
      stub_request(:post, "https://itunesconnect.apple.com/WebObjects/iTunesConnect.woa/ra/users/itc/10795390202/roles").
        with(body: JSON.parse(itc_read_fixture_file("member_update_roles_developer.json"))).
        to_return(status: 200, body: "", headers: {})

      # read member roles before role: appmanager, apps: 12345
      stub_request(:get, "https://itunesconnect.apple.com/WebObjects/iTunesConnect.woa/ra/users/itc/10791511390202/roles").
        to_return(status: 200, body: itc_read_fixture_file(File.join('member_read_roles_before_appmanager_single_app.json')),
                  headers: { "Content-Type" => "application/json" })

      # update member role: appmanager, apps: 12345
      stub_request(:post, "https://itunesconnect.apple.com/WebObjects/iTunesConnect.woa/ra/users/itc/10791511390202/roles").
        with(body: JSON.parse(itc_read_fixture_file("member_update_roles_appmanager_single_app.json"))).
        to_return(status: 200, body: "", headers: {})

      # Load member list
      stub_request(:get, "https://itunesconnect.apple.com/WebObjects/iTunesConnect.woa/ra/users/itc").
        to_return(status: 200, body: itc_read_fixture_file(File.join('member_list.json')),
         headers: { "Content-Type" => "application/json" })
    end
  end
end
