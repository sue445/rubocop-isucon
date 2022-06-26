# Benchmark report
## [parse_table.rb](parse_table.rb)
```bash
$ ruby -v
ruby 3.1.2p20 (2022-04-12 revision 4491bb740a) [x86_64-darwin21]

$ bundle exec ruby benchmark/parse_table.rb
Warming up --------------------------------------
SqlParser.parse_tables
                         3.315k i/100ms
RuboCop::Isucon::GDA::Client#table_names
                        31.000  i/100ms
Calculating -------------------------------------
SqlParser.parse_tables
                         31.672k (± 7.5%) i/s -    159.120k in   5.056991s
RuboCop::Isucon::GDA::Client#table_names
                        418.846  (± 9.8%) i/s -      2.077k in   5.023313s

Comparison:
SqlParser.parse_tables:    31671.6 i/s
RuboCop::Isucon::GDA::Client#table_names:      418.8 i/s - 75.62x  (± 0.00) slower
```

## [memorize.rb](memorize.rb)
```bash
$ ruby -v
ruby 3.1.2p20 (2022-04-12 revision 4491bb740a) [x86_64-darwin21]

$ bundle exec ruby benchmark/memorize.rb
Warming up --------------------------------------
DefineMethodWithInstanceVariableMemorizer
                        79.346k i/100ms
DefineMethodWithHashMemorizer
                       158.601k i/100ms
  ClassEvalMemorizer   497.389k i/100ms
Calculating -------------------------------------
DefineMethodWithInstanceVariableMemorizer
                        701.502k (±13.8%) i/s -      3.491M in   5.087557s
DefineMethodWithHashMemorizer
                          1.549M (± 2.3%) i/s -      7.771M in   5.018555s
  ClassEvalMemorizer      4.866M (± 8.1%) i/s -     24.372M in   5.061882s

Comparison:
  ClassEvalMemorizer:  4865569.7 i/s
DefineMethodWithHashMemorizer:  1549386.5 i/s - 3.14x  (± 0.00) slower
DefineMethodWithInstanceVariableMemorizer:   701502.0 i/s - 6.94x  (± 0.00) slower
```

## [shell.rb](shell.rb)
```bash
$ ruby -v
ruby 3.1.2p20 (2022-04-12 revision 4491bb740a) [x86_64-darwin21]

$ bundle exec ruby benchmark/shell.rb
Warming up --------------------------------------
digest_with_shell_openssl
                         4.000  i/100ms
digest_with_ruby_openssl
                        36.540k i/100ms
Calculating -------------------------------------
digest_with_shell_openssl
                         92.458  (±22.7%) i/s -    424.000  in   4.985251s
digest_with_ruby_openssl
                        453.025k (±10.1%) i/s -      2.265M in   5.057335s

Comparison:
digest_with_ruby_openssl:   453024.6 i/s
digest_with_shell_openssl:       92.5 i/s - 4899.78x  (± 0.00) slower
```
