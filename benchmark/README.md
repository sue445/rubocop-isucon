# Benchmark report
## [parse_table.rb](parse_table.rb)
```bash
$ ruby -v
ruby 3.0.2p107 (2021-07-07 revision 0db68f0233) [x86_64-darwin20]

$ bundle exec ruby benchmark/parse_table.rb
Warming up --------------------------------------
RuboCop::Isucon::SqlParser#parse_tables
                         4.966k i/100ms
RuboCop::Isucon::GDA::Client#table_names
                        87.000  i/100ms
Calculating -------------------------------------
RuboCop::Isucon::SqlParser#parse_tables
                         49.124k (± 0.5%) i/s -    248.300k in   5.054728s
RuboCop::Isucon::GDA::Client#table_names
                        846.523  (± 1.5%) i/s -      4.263k in   5.037134s
```

## [memorize.rb](memorize.rb)
```bash
$ ruby -v
ruby 3.0.2p107 (2021-07-07 revision 0db68f0233) [x86_64-darwin20]

$ bundle exec ruby benchmark/memorize.rb
Warming up --------------------------------------
DefineMethodMemorizer
                       100.715k i/100ms
InstanceEvalMemorizer
                       710.328k i/100ms
Calculating -------------------------------------
DefineMethodMemorizer
                          1.008M (± 0.7%) i/s -      5.136M in   5.098066s
InstanceEvalMemorizer
                          7.099M (± 0.6%) i/s -     35.516M in   5.003395s
```
