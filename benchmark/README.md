# Benchmark report
## [parse_table.rb](parse_table.rb)
```bash
$ ruby -v
ruby 3.1.0p0 (2021-12-25 revision fb4df44d16) [x86_64-darwin21]

$ bundle exec ruby benchmark/parse_table.rb
Warming up --------------------------------------
RuboCop::Isucon::SqlParser.parse_tables
                         3.217k i/100ms
RuboCop::Isucon::GDA::Client#table_names
                        42.000  i/100ms
Calculating -------------------------------------
RuboCop::Isucon::SqlParser.parse_tables
                         31.132k (± 9.7%) i/s -    154.416k in   5.029165s
RuboCop::Isucon::GDA::Client#table_names
                        418.115  (± 5.3%) i/s -      2.100k in   5.037008s
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
