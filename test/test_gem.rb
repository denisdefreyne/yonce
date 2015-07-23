class Yonce::GemTest < Yonce::TestCase
  def test_build
    # Require clean environment
    Dir['yonce-*.gem'].each { |f| FileUtils.rm(f) }

    # Build
    files_before = Set.new Dir['**/*']
    stdout = StringIO.new
    stderr = StringIO.new
    piper = ::Yonce::Piper.new(stdout: stdout, stderr: stderr)
    piper.run(%w( gem build yonce.gemspec ), nil)
    files_after = Set.new Dir['**/*']

    # Check new files
    diff = files_after - files_before
    assert_equal 1, diff.size
    assert_match(/^yonce-.*\.gem$/, diff.to_a[0])
  ensure
    Dir['yonce-*.gem'].each { |f| FileUtils.rm(f) }
  end
end
