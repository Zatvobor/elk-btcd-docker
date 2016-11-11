# encoding: utf-8
require "logstash/devutils/rspec/spec_helper"

module LogStash::Environment
  # running the grok code outside a logstash package means
  # LOGSTASH_HOME will not be defined, so let's set it here
  # before requiring the grok filter
  unless self.const_defined?(:LOGSTASH_HOME)
    LOGSTASH_HOME = File.expand_path("../../../", __FILE__)
  end

  # also :pattern_path method must exist so we define it too
  unless self.method_defined?(:pattern_path)
    def pattern_path(path)
      ::File.join(LOGSTASH_HOME, "patterns", path)
    end
  end
end

require "logstash/filters/grok"
require "logstash/filters/mutate"

describe "BMGR: Processed" do
  config <<-'FILTER'
    filter {
       grok {
        match => { "message" => "BMGR: Processed %{NUMBER:blocks} block in the last %{DATA:time_from_last_processed_block}s \(%{NUMBER:transactions} transactions, height %{NUMBER:height}, %{TIMESTAMP_ISO8601:timestamp} \+0000 UTC\)" }
        add_tag => [ "BMGR", "processed", "block" ]
       }
       mutate {
         convert => { "blocks" => "integer" }
         convert => { "transactions" => "integer" }
         convert => { "height" => "integer" }
       }
    }
  FILTER

  sample "13:39:19 2016-11-07 [INF] BMGR: Processed 1 block in the last 1m4.87s (2459 transactions, height 437757, 2016-11-07 13:39:09 +0000 UTC)" do
    insist { subject.get("blocks") } == 1
    insist { subject.get("time_from_last_processed_block") } == "1m4.87"
    insist { subject.get("transactions") } == 2459
    insist { subject.get("height") } == 437757
    insist { subject.get("timestamp") } == "2016-11-07 13:39:09"
    insist { subject.get("tags") } == ["BMGR", "processed", "block"]
  end
end

describe "BMGR: Rejected transaction" do
  config <<-'FILTER'
    filter {
      grok {
        match => { "message" => "BMGR: Rejected transaction %{DATA:hash} from %{HOSTPORT:from} \(outbound\): %{GREEDYDATA:reason}" }
        add_tag => [ "BMGR", "rejected", "transaction" ]
      }
      grok {
        match => { "reason" => "transaction %{DATA} is not standard" }
        add_tag => [ "is_not_finalized" ]
      }
      grok {
        match => { "reason" => "output %{DATA} already spent by transaction" }
        add_tag => [ "already_spent" ]
      }
    }
  FILTER

  sample "10:46:12 2016-11-04 [DBG] BMGR: Rejected transaction 45bdaecd5efaa7fe9b3c492fe1220d849a629a9ee8bf0d6d83abe60c28079a50 from 148.251.3.170:8333 (outbound): transaction 45bdaecd5efaa7fe9b3c492fe1220d849a629a9ee8bf0d6d83abe60c28079a50 is not standard: transaction is not finalized" do
    insist { subject.get("hash") } == "45bdaecd5efaa7fe9b3c492fe1220d849a629a9ee8bf0d6d83abe60c28079a50"
    insist { subject.get("from") } == "148.251.3.170:8333"
    insist { subject.get("reason") } == "transaction 45bdaecd5efaa7fe9b3c492fe1220d849a629a9ee8bf0d6d83abe60c28079a50 is not standard: transaction is not finalized"
    insist { subject.get("tags") }.include? "is_not_finalized"
  end

  sample "09:18:00 2016-11-04 [DBG] BMGR: Rejected transaction e86402932636afd51c8989df84ebfd1692e97dbfded7ce0efe7816032bed7ca1 from 208.66.68.127:8333 (outbound): output f1f53bfb85992ee9cb278a951aef7a7af340f94652b8701717917f5797bac66a:1 already spent by transaction e580b5123cb45b01803f653d0629fadb582fabcc7e735afc13942793a4d0e9ee in the memory pool" do
    insist { subject.get("hash") } == "e86402932636afd51c8989df84ebfd1692e97dbfded7ce0efe7816032bed7ca1"
    insist { subject.get("from") } == "208.66.68.127:8333"
    insist { subject.get("reason") } == "output f1f53bfb85992ee9cb278a951aef7a7af340f94652b8701717917f5797bac66a:1 already spent by transaction e580b5123cb45b01803f653d0629fadb582fabcc7e735afc13942793a4d0e9ee in the memory pool"
    insist { subject.get("tags") }.include? "already_spent"
  end

  sample "10:46:12 2016-11-04 [DBG] BMGR: Rejected transaction e143550e70e41fefead1792cc1490f5b1b23d86cc20737553f359bdaa560d962 from 138.201.95.25:8333 (outbound): orphan transaction size of 7585 bytes is larger than max allowed size of 5000 bytes" do
    insist { subject.get("hash") } == "e143550e70e41fefead1792cc1490f5b1b23d86cc20737553f359bdaa560d962"
    insist { subject.get("from") } == "138.201.95.25:8333"
    insist { subject.get("reason") } == "orphan transaction size of 7585 bytes is larger than max allowed size of 5000 bytes"
  end
end

describe "TXMP events" do
  config <<-'FILTER'
    filter {
      grok {
        match => { "message" => "TXMP: Processing transaction %{DATA:hash}$" }
        add_tag => [ "TXMP", "transaction", "processing" ]
      }
      grok {
        match => { "message" => "TXMP: Accepted transaction %{DATA:hash} \(pool size: %{NUMBER:pool_size}\)" }
        add_tag => [ "TXMP", "transaction", "accepted" ]
      }
      mutate {
        convert => { "pool_size" => "integer" }
      }
      grok {
        match => { "message" => "TXMP: Stored orphan transaction %{DATA:hash} \(total: %{NUMBER:total}\)" }
        add_tag => [ "TXMP", "transaction", "stored", "orphan" ]
      }
      mutate {
        convert => { "total" => "integer" }
      }
    }
  FILTER

  sample "14:24:12 2016-11-10 [TRC] TXMP: Processing transaction 5cf8cb5ef0d033c36115c36dc8320faa672c7c740cff3826dc43af996ca8e161" do
    insist { subject.get("hash") } == "5cf8cb5ef0d033c36115c36dc8320faa672c7c740cff3826dc43af996ca8e161"
    insist { subject.get("tags") }.include? "processing"
  end
  sample "14:27:11 2016-11-10 [DBG] TXMP: Accepted transaction 102d59d3f2457413b86413b151abba0971e1627d1ab89d38986e924badead25f (pool size: 315)" do
    insist { subject.get("hash") } == "102d59d3f2457413b86413b151abba0971e1627d1ab89d38986e924badead25f"
    insist { subject.get("pool_size") } == 315
    insist { subject.get("tags") }.include? "accepted"
  end
  sample "14:24:12 2016-11-10 [DBG] TXMP: Stored orphan transaction 5cf8cb5ef0d033c36115c36dc8320faa672c7c740cff3826dc43af996ca8e161 (total: 12)" do
    insist { subject.get("hash") } == "5cf8cb5ef0d033c36115c36dc8320faa672c7c740cff3826dc43af996ca8e161"
    insist { subject.get("total") } == 12
    insist { subject.get("tags") }.include? "stored"
    insist { subject.get("tags") }.include? "orphan"
  end
end

describe "CHAN events" do
  config <<-'FILTER'
    filter {
      grok {
        match => { "message" => "CHAN: Processing block %{DATA:hash}$" }
        add_tag => [ "CHAN", "block", "processing" ]
      }
      grok {
        match => { "message" => "CHAN: Accepted block %{DATA:hash}$" }
        add_tag => [ "CHAN", "block", "accepted" ]
      }
    }
  FILTER

  sample "14:24:08 2016-11-10 [TRC] CHAN: Processing block 00000000000000000211f8216234845429284ac730021674edfa9de249bc0227" do
    insist { subject.get("hash") } == "00000000000000000211f8216234845429284ac730021674edfa9de249bc0227"
    insist { subject.get("tags") }.include? "processing"
  end

  sample "11:10:31 2016-11-11 [DBG] CHAN: Accepted block 00000000000000000307a483f397c8cd4cb69b8b72e05aea5dda889695fed377" do
    insist { subject.get("hash") } == "00000000000000000307a483f397c8cd4cb69b8b72e05aea5dda889695fed377"
    insist { subject.get("tags") }.include? "accepted"
  end
end

describe "BCDB events" do
  config <<-'FILTER'
    filter {
      grok {
        match => { "message" => "BCDB: Added block %{DATA:hash} to pending blocks" }
        add_tag => [ "BCDB", "block", "added", "pending" ]
      }
      grok {
        match => { "message" => "BCDB: Storing block %{DATA:hash}$" }
        add_tag => [ "BCDB", "block", "storing" ]
      }
    }
  FILTER

  sample "11:10:31 2016-11-11 [TRC] BCDB: Added block 0000000000000000006b02a564eb2eb731d512d4f2af1f75c3baf3713a539319 to pending blocks" do
    insist { subject.get("hash") } == "0000000000000000006b02a564eb2eb731d512d4f2af1f75c3baf3713a539319"
    insist { subject.get("tags") }.include? "added"
    insist { subject.get("tags") }.include? "pending"
  end
  sample "11:10:31 2016-11-11 [TRC] BCDB: Storing block 0000000000000000006b02a564eb2eb731d512d4f2af1f75c3baf3713a539319" do
    insist { subject.get("hash") } == "0000000000000000006b02a564eb2eb731d512d4f2af1f75c3baf3713a539319"
    insist { subject.get("tags") }.include? "storing"
  end
end
