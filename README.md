# Prometheus Parser

A prometheus parser for Crystal.

## Installation

1. Add the dependency to your `shard.yml`:
```yaml
dependencies:
  amqp-client:
    github: 84codes/prometheus.cr
```
2. Run `shards install`

## Usage

```crystal
require "prometheus"

parsed = Prometheus::Parser.parse("response_packet_get_children_cache_hits 0.0")
parsed.first[:key] == "response_packet_get_children_cache_hits"
parsed.first[:value] == 0.0
```

1. [Fork it](https://github.com/84codes/prometheus.cr/fork)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
