require "spec"
require "../src/parser"

describe Prometheus::Parser do
  it "should parse simple metric" do
    raw = "response_packet_get_children_cache_hits 0.0"
    res = Prometheus::Parser.parse(raw)
    res.size.should eq 1
    res.first[:key].should eq "response_packet_get_children_cache_hits"
    res.first[:value].should eq 0.0
    res.first[:attrs].size.should eq 0
  end

  it "should parse many metrics" do
    raw = <<-METRICS
    kafka_cluster_partition_underminisr 0
    kafka_network_requestmetrics_totaltimems 179494
    METRICS

    res = Prometheus::Parser.parse(raw)
    res.size.should eq 2
    res.first[:key].should eq "kafka_cluster_partition_underminisr"
    res.first[:value].should eq 0.0
    res.first[:attrs].size.should eq 0
    res[1][:key].should eq "kafka_network_requestmetrics_totaltimems"
    res[1][:value].should eq 179_494
    res[1][:attrs].size.should eq 0
  end

  it "should parse attrs" do
    raw = <<-METRICS
    kafka_server_socket_server_metrics{network_processor="8",listener="sasl_ssl",key="connection-count"} 0.0
    METRICS
    res = Prometheus::Parser.parse(raw)
    res.size.should eq 1
    res.first[:key].should eq "kafka_server_socket_server_metrics"
    res.first[:value].should eq 0.0
    attrs = {
      "network_processor" => "8",
      "listener"          => "sasl_ssl",
      "key"               => "connection-count",
    }
    res.first[:attrs].should eq attrs
  end

  it "should parse attrs with spaces" do
    raw = <<-METRICS
    kafka_server_socket_server_metrics{network_processor = "8" , listener="sasl_ssl" ,key="connection-count"} 0.0
    METRICS
    res = Prometheus::Parser.parse(raw)
    res.size.should eq 1
    res.first[:key].should eq "kafka_server_socket_server_metrics"
    res.first[:value].should eq 0.0
    attrs = {
      "network_processor" => "8",
      "listener"          => "sasl_ssl",
      "key"               => "connection-count",
    }
    res.first[:attrs].should eq attrs
  end

  it "should skip comments" do
    raw = <<-METRICS
    # HELP .................
    # TYPE ...................
    kafka_server_socket_server_metrics{network_processor="8",listener="sasl_ssl",key="connection-count"} 0.0
    METRICS
    res = Prometheus::Parser.parse(raw)
    res.size.should eq 1
    res.first[:key].should eq "kafka_server_socket_server_metrics"
  end

  it "should raise error on bad key" do
    raw = <<-METRICS
    kafka!_server_socket_server_metrics 0.0
    METRICS
    expect_raises(Prometheus::Parser::Invalid) do
      Prometheus::Parser.parse(raw)
    end
  end

  it "should handle NaN values" do
    raw = <<-METRICS
    kafka_server_socket_server_metrics NaN
    METRICS
    res = Prometheus::Parser.parse(raw)
    res.first[:value].nan?.should be_true
  end

  it "should handle 8.123213E-28" do
    raw = <<-METRICS
    kafka_server_socket_server_metrics 8.123213E-28
    METRICS
    res = Prometheus::Parser.parse(raw)
    res.first[:value].should eq 8.123213e-28
  end

  it "should handle quoted values in attributes" do
    raw = <<-METRICS
    kafka_log_LogManager_Value{name="LogDirectoryOffline",logDirectory=""/var/lib/kafka"",} 0.0
    METRICS
    res = Prometheus::Parser.parse(raw)
    res.first[:attrs]["name"].should eq "LogDirectoryOffline"
    res.first[:attrs]["logDirectory"].should eq "\"/var/lib/kafka\""
    res.first[:value].should eq 0.0
  end

  it "should handle decimals values in attributes" do
    raw = <<-METRICS
    concurrent_request_processing_in_commit_processor{quantile="0.5",} NaN
    METRICS
    res = Prometheus::Parser.parse(raw)
    res.first[:attrs]["quantile"].should eq "0.5"
    res.first[:value].nan?.should be_true
  end

  it "should handle space values in attributes" do
    raw = <<-METRICS
    jvm_memory_pool_allocated_bytes_total{pool="CodeHeap 'non-profiled nmethods'",} 2387840.0
    METRICS
    res = Prometheus::Parser.parse(raw)
    res.first[:attrs]["pool"].should eq "CodeHeap 'non-profiled nmethods'"
    res.first[:value].should eq 2387840.0
  end

  it "should handle plus (+) values in attributes" do
    raw = <<-METRICS
    jvm_info{version="11.0.16+8-post-Debian-1deb11u1",vendor="Debian",runtime="OpenJDK Runtime Environment",} 1.0
    METRICS
    res = Prometheus::Parser.parse(raw)
    res.first[:attrs]["version"].should eq "11.0.16+8-post-Debian-1deb11u1"
  end
end
