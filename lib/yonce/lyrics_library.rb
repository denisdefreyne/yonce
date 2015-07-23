require 'faraday'
require 'json'
require 'logger'

module Yonce
  class LyricsLibrary
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

        lyrics = result.body.force_encoding('UTF-8').split(' ').first(16).join(' ')

        { name: song, lyrics: lyrics }
      end
    end
  end
end
