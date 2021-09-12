# Benchmark report
## [parse_table.rb](parse_table.rb)
```bash
$ ruby -v
ruby 3.0.2p107 (2021-07-07 revision 0db68f0233) [x86_64-darwin20]

$ bundle exec ruby benchmark/parse_table.rb
Warming up --------------------------------------
RuboCop::Isucon::SqlParser#parse_tables
                       909.000  i/100ms
RuboCop::Isucon::GdaHelper#table_names
                       142.000  i/100ms
Calculating -------------------------------------
RuboCop::Isucon::SqlParser#parse_tables
                         18.736k (±24.3%) i/s -     88.173k in   5.011931s
RuboCop::Isucon::GdaHelper#table_names
                          1.308k (±15.4%) i/s -      6.390k in   5.001929s
```
