# frozen_string_literal: true

require "asciidoctor"
require "pry"

module Asciidoctor
  module Substitutors
    def sub_replacements text
      REPLACEMENTS.each do |pattern, replacement, restore|
        text = text.gsub(pattern) { do_replacement $~, replacement, restore }
      end if ReplaceableTextRx.match? text
      text
    end
  end
end