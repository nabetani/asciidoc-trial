require "asciidoctor-pdf"
require_relative "asciidoctor-nabehelper"

module Asciidoctor
  module PDF
    class Converter
      include NabeHelper

      alias_method :convert_table_original, :convert_table
      def convert_table node
        if three_state(node.attr('nobreak'), 'nobreak')
          keep_together do
            convert_table_original node
          end
        else
          convert_table_original node
        end
      end
    end
  end
end
