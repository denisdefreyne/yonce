# encoding: utf-8
require File.expand_path('./yonce/lyrics_library', File.dirname(__FILE__))

module Yonce #:nodoc:
  def self.run
    notes = %w( ♩ ♪ ♫ ♬ )
    lib = LyricsLibrary.new
    #lyrics = ['All the single ladies']
    begin
      song = lib.lyrics.sample
      song_title = song[:name]
      lyrics = LyricsLibrary.sample(song[:lyrics])
    rescue LyricsLibrary::NoLyrics
      retry
    end
    puts "#{notes.sample} #{lyrics} #{notes.sample}\t (Song: \"#{song_title}\")"
  end
end
