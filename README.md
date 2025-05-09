# RuboCop ISUCON
RuboCop plugin for ruby reference implementation of [ISUCON](https://github.com/isucon)

[![Gem Version](https://badge.fury.io/rb/rubocop-isucon.svg)](https://badge.fury.io/rb/rubocop-isucon)
[![test](https://github.com/sue445/rubocop-isucon/actions/workflows/test.yml/badge.svg)](https://github.com/sue445/rubocop-isucon/actions/workflows/test.yml)

## Installation
At first, install [libgda](https://gitlab.gnome.org/GNOME/libgda)

### for Mac (recommended)
```bash
brew install libgda
```

### for Ubuntu, Debian (recommended)
```bash
apt-get install -y libgda-5.0
```

### for CentOS 7
```bash
yum install -y epel-release
yum --enablerepo=epel install -y libgda-devel
```

### for CentOS 8+
```bash
dnf install -y https://pkgs.dyn.su/el8/base/x86_64/raven-release-1.0-2.el8.noarch.rpm
dnf --enablerepo=raven install -y libgda-devel
```

### Installing gem
Add this line to your application's Gemfile:

```ruby
group :development do
  gem 'rubocop-isucon', require: false
end
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install rubocop-isucon

## Usage

Add this line to your application's `.rubocop.yml`

```yaml
plugins:
  - rubocop-isucon

inherit_gem:
  rubocop-isucon:
    # Disable default cops (except Performance cops)
    - "config/enable-only-performance.yml"

AllCops:
  NewCops: enable
  DisplayStyleGuide: true
  # TargetRubyVersion: 3.1

Isucon/Mysql2:
  Database:
    adapter: mysql2
    host: # TODO: Fix this
    database: # TODO: Fix this
    username: isucon
    password: isucon
    encoding: utf8
    port: 3306

Isucon/Sqlite3:
  Database:
    adapter: sqlite3
    database: # TODO: Fix this
```

`Database` isn't configured in `.rubocop.yml`, some cops doesn't work

| cop                                | offense detection          | auto-correct               |
|------------------------------------|----------------------------|----------------------------|
| `Isucon/Mysql2/JoinWithoutIndex`   | `Database` is **required** | Not supported              |
| `Isucon/Mysql2/NPlusOneQuery`      | `Database` is optional     | `Database` is **required** |
| `Isucon/Mysql2/SelectAsterisk`     | `Database` is optional     | `Database` is **required** |
| `Isucon/Mysql2/WhereWithoutIndex`  | `Database` is **required** | Not supported              |
| `Isucon/Sqlite3/JoinWithoutIndex`  | `Database` is **required** | Not supported              |
| `Isucon/Sqlite3/NPlusOneQuery`     | `Database` is optional     | `Database` is **required** |
| `Isucon/Sqlite3/SelectAsterisk`    | `Database` is optional     | `Database` is **required** |
| `Isucon/Sqlite3/WhereWithoutIndex` | `Database` is **required** | Not supported              |

## Documentation
See. https://sue445.github.io/rubocop-isucon/

* `Isucon/Mysql2` department docs : https://sue445.github.io/rubocop-isucon/RuboCop/Cop/Isucon/Mysql2.html
* `Isucon/Shell` department docs : https://sue445.github.io/rubocop-isucon/RuboCop/Cop/Isucon/Shell.html
* `Isucon/Sinatra` department docs : https://sue445.github.io/rubocop-isucon/RuboCop/Cop/Isucon/Sinatra.html
* `Isucon/Sqlite3` department docs : https://sue445.github.io/rubocop-isucon/RuboCop/Cop/Isucon/Sqlite3.html

## Benchmark
See [benchmark/](benchmark/)

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/sue445/rubocop-isucon.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

ISUCON is a trademark or registered trademark of LINE Corporation.

https://isucon.net

## Presentation
* [Fix SQL N\+1 queries with RuboCop](https://speakerdeck.com/sue445/fix-sql-n-plus-one-queries-with-rubocop) at [RubyKaigi 2023](https://rubykaigi.org/2013/) :gem:
