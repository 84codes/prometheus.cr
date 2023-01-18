require "string_scanner"

module Prometheus
  class Parser
    class Invalid < Exception
      def initialize
        super("invalid input")
      end
    end

    KEY_RE        = /[\w:]+/
    VALUE_RE      = /-?\d+\.?\d*E?-?\d*|NaN/
    ATTR_KEY_RE   = /[ \w-]+/
    ATTR_VALUE_RE = %r{\s*"([\\"'\sa-zA-Z0-9\-_/.+]*)"\s*}

    def self.parse(raw)
      s = StringScanner.new(raw)
      res = [] of NamedTuple(key: String, attrs: Hash(String, String), value: Float64)
      until s.eos?
        if s.peek(1) == "#"
          s.scan(/.*\n/)
          next
        end
        key = s.scan KEY_RE
        raise Invalid.new unless key
        attrs = parse_attrs(s)
        value = s.scan VALUE_RE
        raise Invalid.new unless value
        value = value.to_f
        s.scan(/\n/)
        res.push({key: key, attrs: attrs, value: value})
      end
      res
    end

    def self.parse_attrs(s)
      attrs = Hash(String, String).new
      if s.scan(/\s|{/) == "{"
        loop do
          if s.peek(1) == "}"
            s.scan(/}/)
            break
          end
          key = s.scan ATTR_KEY_RE
          raise Invalid.new unless key
          key = key.strip
          s.scan(/=/)
          s.scan ATTR_VALUE_RE

          value = s[1]
          raise Invalid.new unless value
          attrs[key] = value
          break if s.scan(/,|}/) == "}"
        end
        s.scan(/\s/)
      end
      attrs
    end
  end
end
