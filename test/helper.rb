require 'simplecov'
SimpleCov.start

require 'minitest/test'
require 'minitest/spec'
require 'minitest/mock'
require 'minitest/autorun'
require 'yard'
require 'open3'

require 'yonce'

module Yonce::TestHelpers #:nodoc:
  LIB_DIR = File.expand_path(File.dirname(__FILE__) + '/../lib')

  def disable_nokogiri?
    ENV.key?('DISABLE_NOKOGIRI')
  end

  def if_have(*libs)
    libs.each do |lib|
      begin
        require lib
      rescue LoadError
        skip "requiring #{lib} failed"
        return
      end
    end

    yield
  end

  def if_implemented
    yield
  rescue NotImplementedError, NameError
    skip $ERROR_INFO
    return
  end

  def setup
    # Check skipped
    if ENV['skip']
      if ENV['skip'].split(',').include?(self.class.to_s)
        skip 'manually skipped'
      end
    end

    # Clean up
    GC.start

    # Go quiet
    unless ENV['QUIET'] == 'false'
      @orig_stdout = $stdout
      @orig_stderr = $stderr

      $stdout = StringIO.new
      $stderr = StringIO.new
    end
  end

  def teardown
    # Go unquiet
    unless ENV['QUIET'] == 'false'
      $stdout = @orig_stdout
      $stderr = @orig_stderr
    end
  end

  def capturing_stdio(&_block)
    # Store
    orig_stdout = $stdout
    orig_stderr = $stderr

    # Run
    $stdout = StringIO.new
    $stderr = StringIO.new
    yield
    { stdout: $stdout.string, stderr: $stderr.string }
  ensure
    # Restore
    $stdout = orig_stdout
    $stderr = orig_stderr
  end

  # Adapted from http://github.com/lsegal/yard-examples/tree/master/doctest
  def assert_examples_correct(object)
    P(object).tags(:example).each do |example|
      # Classify
      lines = example.text.lines.map do |line|
        [line =~ /^\s*# ?=>/ ? :result : :code, line]
      end

      # Join
      pieces = []
      lines.each do |line|
        if !pieces.empty? && pieces.last.first == line.first
          pieces.last.last << line.last
        else
          pieces << line
        end
      end
      lines = pieces.map(&:last)

      # Test
      b = binding
      lines.each_slice(2) do |pair|
        actual_out   = eval(pair.first, b)
        expected_out = eval(pair.last.match(/# ?=>(.*)/)[1], b)

        assert_equal expected_out, actual_out,
          "Incorrect example:\n#{pair.first}"
      end
    end
  end

  def assert_contains_exactly(expected, actual)
    assert_equal expected.size, actual.size,
      format('Expected %s to be of same size as %s', actual.inspect, expected.inspect)
    remaining = actual.dup.to_a
    expected.each do |e|
      index = remaining.index(e)
      remaining.delete_at(index) if index
    end
    assert remaining.empty?,
      format('Expected %s to contain all the elements of %s', actual.inspect, expected.inspect)
  end

  def assert_raises_frozen_error
    error = assert_raises(RuntimeError, TypeError) { yield }
    assert_match(/(^can't modify frozen |^unable to modify frozen object$)/, error.message)
  end

  def with_env_vars(hash, &_block)
    orig_env_hash = ENV.to_hash
    hash.each_pair { |k, v| ENV[k] = v }
    yield
  ensure
    orig_env_hash.each_pair { |k, v| ENV[k] = v }
  end

  def on_windows?
    Nanoc.on_windows?
  end

  def command?(cmd)
    which, null = on_windows? ? %w(where NUL) : ['which', '/dev/null']
    system("#{which} #{cmd} > #{null} 2>&1")
  end

  def symlinks_supported?
    File.symlink nil, nil
  rescue NotImplementedError
    return false
  rescue
    return true
  end

  def skip_unless_have_command(cmd)
    skip "Could not find external command \"#{cmd}\"" unless command?(cmd)
  end

  def skip_unless_symlinks_supported
    skip 'Symlinks are not supported by Ruby on Windows' unless symlinks_supported?
  end
end

class Yonce::TestCase < Minitest::Test #:nodoc:
  include Yonce::TestHelpers
end

# From nanoc project
class Yonce::Piper
  class Error < ::StandardError
    def initialize(command, exit_code)
      @command = command
      @exit_code = exit_code
    end

    def message
      "command exited with a nonzero status code #{@exit_code} (command: #{@command.join(' ')})"
    end
  end

  # @param [IO] stdout
  # @param [IO] stderr
  def initialize(opts={})
    @stdout = opts[:stdout] || $stdout
    @stderr = opts[:stderr] || $stderr
  end

  # @param [Array<String>] cmd
  #
  # @param [String, nil] input
  def run(cmd, input)
    Open3.popen3(*cmd) do |stdin, stdout, stderr, wait_thr|
      stdout_thread = Thread.new { @stdout << stdout.read }
      stderr_thread = Thread.new { @stderr << stderr.read }

      if input
        stdin << input
      end
      stdin.close

      stdout_thread.join
      stderr_thread.join

      exit_status = wait_thr.value
      unless exit_status.success?
        raise Error.new(cmd, exit_status.to_i)
      end
    end
  end
end

# Unexpected system exit is unexpected
::Minitest::Test::PASSTHROUGH_EXCEPTIONS.delete(SystemExit)

# A more precise inspect method for Time improves assert failure messages.
#
class Time
  def inspect
    strftime("%a %b %d %H:%M:%S.#{format('%06d', usec)} %Z %Y")
  end
end
