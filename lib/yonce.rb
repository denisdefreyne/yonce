# encoding: utf-8

module Yonce #:nodoc:
  def self.run
    notes = %w( ♩ ♪ ♫ ♬ )
    lyrics = ['All the single ladies']
    puts "#{notes.sample} #{lyrics.sample} #{notes.sample}"
  end
end
