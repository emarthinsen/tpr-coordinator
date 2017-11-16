require 'rspec_api_documentation'
require 'factory_girl_rails'
require 'helper_methods'
require 'webmock/rspec'
require 'timecop'
require 'fantaskspec'
require 'database_cleaner'

# require 'task_helper' 

# This file was generated by the `rails generate rspec:install` command. Conventionally, all
# specs live under a `spec` directory, which RSpec adds to the `$LOAD_PATH`.
# The generated `.rspec` file contains `--require spec_helper` which will cause
# this file to always be loaded, without a need to explicitly require it in any
# files.
#
# Given that it is always loaded, you are encouraged to keep this file as
# light-weight as possible. Requiring heavyweight dependencies from this file
# will add to the boot time of your test suite on EVERY test run, even for an
# individual file that may not need all of that loaded. Instead, consider making
# a separate helper file that requires the additional dependencies and performs
# the additional setup, and require it from the spec files that actually need
# it.
#
# See http://rubydoc.info/gems/rspec-core/RSpec/Core/Configuration
#

ENV['LOG_LEVEL'] = 'warn'
ENV['SHIPSTATION_API_SECRET'] = 'test_api_secret'
ENV['SHIPSTATION_API_KEY'] = 'test_api_key'
ENV['SHIPPO_TOKEN'] = 'shippo_test_b9b68824dbd11b65305ea9714a039287c499b6ff'
ENV['FROM_ADDRESS_PHONE_NUMBER'] = '123-456-7890'
ENV['HTTP_AUTH_TOKENS'] = 'myaccesstoken'
ENV['GMAIL_USERNAME'] = 'gmail_test_user'
ENV['GMAIL_PASSWORD'] = 'gmail_test_password'
ENV['UNCOMMON_GOODS_INVOICING_EMAILS'] = 'orders@ucg.com,foo@bar.com'
ENV['INVOICE_FROM_EMAIL_ADDRESS'] = 'billing@foo.com'
ENV['EMAILS_TO_NOTIFY_OF_IMPORT'] = 'testnotify@foo.com'

RSpec.configure do |config|
  # rspec-expectations config goes here. You can use an alternate
  # assertion/expectation library such as wrong or the stdlib/minitest
  # assertions if you prefer.
  config.expect_with :rspec do |expectations|
    # This option will default to `true` in RSpec 4. It makes the `description`
    # and `failure_message` of custom matchers include text for helper methods
    # defined using `chain`, e.g.:
    #     be_bigger_than(2).and_smaller_than(4).description
    #     # => "be bigger than 2 and smaller than 4"
    # ...rather than:
    #     # => "be bigger than 2"
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  # rspec-mocks config goes here. You can use an alternate test double
  # library (such as bogus or mocha) by changing the `mock_with` option here.
  config.mock_with :rspec do |mocks|
    # Prevents you from mocking or stubbing a method that does not exist on
    # a real object. This is generally recommended, and will default to
    # `true` in RSpec 4.
    mocks.verify_partial_doubles = true
  end

  # This option will default to `:apply_to_host_groups` in RSpec 4 (and will
  # have no way to turn it off -- the option exists only for backwards
  # compatibility in RSpec 3). It causes shared context metadata to be
  # inherited by the metadata hash of host groups and examples, rather than
  # triggering implicit auto-inclusion in groups with matching metadata.
  # config.shared_context_metadata_behavior = :apply_to_host_groups

  # Many RSpec users commonly either run the entire suite or an individual
  # file, and it's useful to allow more verbose output when running an
  # individual spec file.
  # if config.files_to_run.one?
  #   # Use the documentation formatter for detailed output,
  #   # unless a formatter has already been configured
  #   # (e.g. via a command-line flag).
  #   config.default_formatter = "doc"
  # end
  #

  # Set up FactoryGirl
  config.include FactoryGirl::Syntax::Methods

  # infer rake task :type
  config.infer_rake_task_specs_from_file_location!

  config.before(:suite) do
    begin
      DatabaseCleaner.start
      FactoryGirl.lint
    ensure
      DatabaseCleaner.clean
    end
  end

  config.after do
    Timecop.return
  end

end

RspecApiDocumentation.configure do |config|
  config.format = :markdown
  config.api_name = 'The Public Radio API Documentation'
  config.request_headers_to_include = ['Authorization']
  config.response_headers_to_include = ['Content-Type']
  config.request_body_formatter = :json
end
