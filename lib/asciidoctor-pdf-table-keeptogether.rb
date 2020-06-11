require "asciidoctor-pdf"
require_relative "asciidoctor-nabehelper"

module Asciidoctor
  module PDF
    class Converter
      include NabeHelper

      alias_method :convert_table_original, :convert_table
      def convert_table node
        p [ node.caption, node.attr('nobreak') ]
        if three_state(node.attr('nobreak'), 'nobreak')
          puts( "nobreak" )
          keep_together do
            convert_table_original node
          end
        else
          puts( "standard" )
          convert_table_original node
        end
      end
    end
  end
end
