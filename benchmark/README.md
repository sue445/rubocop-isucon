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
ruby 3.1.2p20 (2022-04-12 revision 4491bb740a) [x86_64-darwin21]

$ bundle exec ruby benchmark/memorize.rb
Warming up --------------------------------------
DefineMethodWithInstanceVariableMemorizer
                        79.803k i/100ms
DefineMethodWithHashMemorizer
                        96.856k i/100ms
  ClassEvalMemorizer   398.761k i/100ms
Calculating -------------------------------------
DefineMethodWithInstanceVariableMemorizer
                        731.070k (± 6.4%) i/s -      3.671M in   5.042419s
DefineMethodWithHashMemorizer
                          1.391M (±19.3%) i/s -      6.296M in   5.003688s
  ClassEvalMemorizer      5.003M (± 2.4%) i/s -     25.122M in   5.024651s
```
