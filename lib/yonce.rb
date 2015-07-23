# encoding: utf-8
require File.expand_path('./yonce/lyrics_library', File.dirname(__FILE__))

module Yonce #:nodoc:
  def self.run
    notes = %w( ♩ ♪ ♫ ♬ )
    lib = LyricsLibrary.new
    #lyrics = ['All the single ladies']
    lyrics = lib.lyrics
    puts "#{notes.sample} #{lyrics.sample[:lyrics]} #{notes.sample}"
  end
end
