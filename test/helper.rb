require_relative '../lib/silence_warnings'

silence_warnings do
  require "rack/test"

  # Load the testing framework
  require 'minitest/spec'
  require 'minitest/reporters'
  require 'minitest/autorun'
end

class WarningIO < StringIO
  IGNORE_WARNINGS = [
    /useless use/,
    /gems\/websocket-extensions-0.1.3.+warning:/,
    /\/lib\/puma.+warning:/,
  ]

  def initialize(stderr)
    super("")
    @stderr = stderr
  end

  def puts(s)
    if !s.is_a?(String) || ENV['VERBOSE'] || IGNORE_WARNINGS.none?{ |pattern| pattern.match(s) }
      @stderr.puts(s)
    end
  end

  def write(s)
    if !s.is_a?(String) || ENV['VERBOSE'] || IGNORE_WARNINGS.none?{ |pattern| pattern.match(s) }
      @stderr.write(s)
    end
  end
end

# Add a warning ignorer
old_stderr = $stderr
$stderr = WarningIO.new(old_stderr)

class MiniTest::Test
  remove_method :setup if respond_to? :setup
  def setup
  end

  alias_method :setup_base, :setup

  remove_method :teardown if respond_to? :teardown
  def teardown
  end

  alias_method :teardown_base, :teardown
end
