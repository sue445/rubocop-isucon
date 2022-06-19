# Benchmark report
## [parse_table.rb](parse_table.rb)
```bash
$ ruby -v
ruby 3.1.2p20 (2022-04-12 revision 4491bb740a) [x86_64-darwin21]

$ bundle exec ruby benchmark/parse_table.rb
Warming up --------------------------------------
SqlParser.parse_tables
                         2.758k i/100ms
RuboCop::Isucon::GDA::Client#table_names
                        18.000  i/100ms
Calculating -------------------------------------
SqlParser.parse_tables
                         31.022k (± 7.5%) i/s -    154.448k in   5.008336s
RuboCop::Isucon::GDA::Client#table_names
                        410.141  (±10.0%) i/s -      2.034k in   5.026695s
```

## [memorize.rb](memorize.rb)
```bash
$ ruby -v
ruby 3.1.0p0 (2021-12-25 revision fb4df44d16) [x86_64-darwin21]

$ bundle exec ruby benchmark/memorize.rb
Warming up --------------------------------------
DefineMethodWithInstanceVariableMemorizer
                        49.496k i/100ms
DefineMethodWithHashMemorizer
                       106.697k i/100ms
  ClassEvalMemorizer   394.612k i/100ms
Calculating -------------------------------------
DefineMethodWithInstanceVariableMemorizer
                        635.641k (±16.3%) i/s -      3.118M in   5.060364s
DefineMethodWithHashMemorizer
                          1.368M (±13.9%) i/s -      6.722M in   5.046721s
  ClassEvalMemorizer      4.422M (±11.2%) i/s -     22.098M in   5.084224s
```
