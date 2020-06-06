module Asciidoctor
  module NabeHelper
    def get_node_attriute_float node, name, fallback
      t = node.attributes[name]
      return fallback unless t

      begin
        return Float(t)
      rescue ArgumentError => e
        raise ArgumentError, "#{name} value should be float value, but it is #{t.inspect} (#{e.inspect})"
      end
    end

    def get_node_attriute_float_array node, name, fallback
      t = node.attributes[name]
      return fallback unless t

      begin
        return t.split(",").map{ |e| Float(e.strip) }
      rescue ArgumentError => e
        raise ArgumentError, "#{name} value should be array of float value, but it is #{t.inspect} (#{e.inspect})"
      end
    end
  end
end
