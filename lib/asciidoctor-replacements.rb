# frozen_string_literal: true

require "asciidoctor"
require "pry"
require_relative "asciidoctor-nabehelper"

module Asciidoctor
  module Substitutors
    def sub_replacements text
      use = NabeHelper.three_state( self.document.attr( "use-replacement" ), "use-replacement" )
      if use==true || use.nil?
        if ReplaceableTextRx.match? text
          REPLACEMENTS.each do |pattern, replacement, restore|
            text = text.gsub(pattern) { do_replacement $~, replacement, restore }
          end 
        end
      end
      text
    end
  end
end