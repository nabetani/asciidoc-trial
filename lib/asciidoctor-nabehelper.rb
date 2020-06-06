module Asciidoctor
  module NabeHelper
    def get_node_attriute node, name, fallback
      t = node.attributes[name]
      return fallback unless t

      begin
        return Float(t)
      rescue ArgumentError => e
        raise ArgumentError, "#{name} value should be floating value, but it is #{t.inspect} (#{e.inspect})"
      end
    end
  end
end
