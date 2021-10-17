# Benchmark report
## [parse_table.rb](parse_table.rb)
```bash
$ ruby -v
ruby 3.0.2p107 (2021-07-07 revision 0db68f0233) [x86_64-darwin20]

$ bundle exec ruby benchmark/parse_table.rb
Warming up --------------------------------------
RuboCop::Isucon::SqlParser.parse_tables
                         4.966k i/100ms
RuboCop::Isucon::GDA::Client#table_names
                        87.000  i/100ms
Calculating -------------------------------------
RuboCop::Isucon::SqlParser.parse_tables
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
DefineMethodWithInstanceVariableMemorizer
                        69.588k i/100ms
DefineMethodWithHashMemorizer
                       151.251k i/100ms
  ClassEvalMemorizer   543.081k i/100ms
Calculating -------------------------------------
DefineMethodWithInstanceVariableMemorizer
                        693.195k (± 1.5%) i/s -      3.479M in   5.020618s
DefineMethodWithHashMemorizer
                          1.502M (± 3.0%) i/s -      7.563M in   5.039638s
  ClassEvalMemorizer      5.534M (± 1.0%) i/s -     27.697M in   5.005370s
```
