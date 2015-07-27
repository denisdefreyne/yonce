require 'faraday'
require 'json'
require 'logger'

module Yonce
  class LyricsLibrary
    class NoLyrics < ::StandardError; end
    class BadSample < ::StandardError; end

    MINIMUM_SAMPLE_SIZE = 6
    MAXIMUM_SAMPLE_SIZE = 16

    def client
      @http_client ||= Faraday.new(url: 'http://lyrics.wikia.com/api.php') do |f|
        logger = ::Logger.new(STDOUT)
        logger.level = ::Logger::FATAL
        f.request :url_encoded
        f.response :logger, logger
        f.adapter Faraday.default_adapter
      end
    end

    def songs(artist='Beyonce')
      results = client.get do |req|
        req.url ''
        req.params['func'] = 'getArtist'
        req.params['artist'] = artist
        req.params['fmt'] = 'json'
      end

      response = JSON.parse(results.body)

      response['albums'].collect {|a| a['songs'] }.flatten
    end

    def lyrics(artist='Beyonce')
      all_songs = self.songs(artist)

      some_songs = all_songs.sample(4)

      results = some_songs.map do |song|
        result = client.get do |req|
          req.url ''
          req.params['artist'] = artist
          req.params['song'] = song
          req.params['fmt'] = 'text'
        end

        lyrics = result.body.force_encoding('UTF-8').gsub(/\[\.\.\.\]/, '')

        { name: song, lyrics: lyrics }
      end
    end

    def self.sample(song)
      lyrics = song.split(' ').reject(&:nil?)
      raise NoLyrics unless lyrics.length >= MINIMUM_SAMPLE_SIZE

      begin
        start_key = (0..(lyrics.length)).to_a.sample
        sample_word_count = (MINIMUM_SAMPLE_SIZE..MAXIMUM_SAMPLE_SIZE).to_a.sample
        sample_lyrics = lyrics[start_key..(lyrics.length)].first(sample_word_count)
        raise BadSample unless sample_lyrics.count >= MINIMUM_SAMPLE_SIZE
      rescue BadSample
        retry
      end

      song_starts_earlier = (start_key > 0)
      song_goes_further = (lyrics.length - start_key > sample_lyrics.length)

      # formatting
      output = ''
      output << '[...] ' if song_starts_earlier
      output << sample_lyrics.join(' ')
      output << ' [...]' if song_goes_further

      output
    end
  end
end
