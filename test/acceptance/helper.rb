require_relative '../helper'

silence_warnings do
  require 'capybara'
  require 'capybara/dsl'
  require 'capybara/minitest'
  require 'capybara/minitest/spec'
  require "selenium/webdriver"
  require 'bundler'
  Bundler.require
end

require_relative '../../rawrs.rb'

# Some of this borrowed from:
# https://www.neotericdesign.com/articles/2018/04/running-your-rails-test-suite-with-dockerized-selenium-on-gitlab-ci/

Capybara.register_server :thin do |app, port, host|
  require "rack/handler/thin"
  Thin::Logging.silent = false
  # Thin::Logging.debug = true # uncomment to see request and response codes
  # Thin::Logging.trace = true # uncomment to see full requests/responses
  Rack::Handler::Thin.run(app, Host: host, Port: port, signals: false)
end
Capybara.server = :thin, { Silent: true }

# When we have a SELENIUM_URL (remote Selenium)
# we need to ensure our test server can be pinged by that remote Selenium.
if ENV['SELENIUM_URL']
  Capybara.server_host = '0.0.0.0'
  Capybara.server_port = server_port

  # Get the application container's IP
  ip = Socket.ip_address_list.detect { |addr| addr.ipv4_private? }.ip_address

  # Use the IP instead of localhost so Capybara knows where to direct Selenium
  if not ENV['SELENIUM_URL'].include?("localhost")
    Capybara.app_host = "http://#{ip}:#{server_port}"
  else
    Capybara.app_host = "http://localhost:#{server_port}"
  end

  puts "Connecting to Selenium:"
  puts "  from: #{Capybara.app_host}"
  puts "    to: #{ENV['SELENIUM_URL']}"
end

Capybara.register_driver :chrome do |app|
  if ENV['SELENIUM_URL']
    # Allow Capybara to connect to the remote Selenium instance
    Capybara::Selenium::Driver.new(app, :browser => :remote,
                                        :url => ENV['SELENIUM_URL'],
                                        :desired_capabilities => Selenium::WebDriver::Remote::Capabilities.chrome)
  else
    Capybara::Selenium::Driver.new(app, :browser => :chrome)
  end
end

Capybara.register_driver :headless_chrome do |app|
  options = ::Selenium::WebDriver::Chrome::Options.new
  options.add_argument("--headless")
  options.add_argument("--no-sandbox")
  options.add_argument("--disable-dev-shm-usage")
  options.add_argument("--disable-gpu")

  args = %w(headless disable-gpu no-sandbox disable-dev-shm-usage)

  if ENV['SELENIUM_URL']
    capabilities = Selenium::WebDriver::Remote::Capabilities.chrome(
      chromeOptions: { args: args }
    )

    # Allow Capybara to connect to the remote Selenium instance
    Capybara::Selenium::Driver.new(app, :browser => :remote,
                                        :options => options,
                                        :url => ENV['SELENIUM_URL'],
                                        :desired_capabilities => capabilities)
  else
    capabilities = Selenium::WebDriver::Remote::Capabilities.chrome(
      chromeOptions: { args: args,
                       binary: "/usr/bin/chromium" }
    )

    Capybara::Selenium::Driver.new(app, :browser => :chrome,
                                        :options => options,
                                        :desired_capabilities => capabilities)
  end
end

class AcceptanceTest < MiniTest::Spec
  include Capybara::DSL
  include Capybara::Minitest::Assertions

  instance_eval do
    # Allow scenario/given to be the DSL of choice
    alias :background :before
    alias :given      :let
  end

  def setup
    setup_base

    Capybara.reset_sessions!
    Capybara.default_max_wait_time = 60
    Capybara.ignore_hidden_elements = false
    Capybara.current_driver = :headless_chrome
  end

  def teardown
    teardown_base

    Capybara.reset_sessions!
    Capybara.current_driver = :headless_chrome
  end

  Capybara.app = RAWRS
  Capybara.register_driver :rack_test do |app|
    Capybara::RackTest::Driver.new(app, :headers => {
      'User-Agent' => 'Capybara'
    })
  end

  extend MiniTest::Spec::DSL

  register_spec_type(self) do |desc, *add|
    add.length > 0 and add[0][:type] == :feature
  end
end

# Allow "feature" to be the DSL of choice

def feature(*args, &block)
  opts = {}
  if args[-1].is_a? Hash
    opts = args.pop
  end
  opts[:type] = :feature
  describe(*args, opts, &block)
end

def scenario(name, *args, &block)
  it(name, *args, &block)
end
