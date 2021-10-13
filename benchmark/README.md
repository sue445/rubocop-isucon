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
                        44.949k i/100ms
  ClassEvalMemorizer   494.989k i/100ms
Calculating -------------------------------------
DefineMethodMemorizer
                        532.864k (±10.3%) i/s -      2.652M in   5.042410s
  ClassEvalMemorizer      4.267M (± 5.2%) i/s -     21.285M in   5.002845s
```
