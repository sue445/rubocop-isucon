# RuboCop Isucon
RuboCop plugin for [ISUCON](https://github.com/isucon)'s ruby reference implementation

[![Build Status](https://github.com/sue445/rubocop-isucon/workflows/test/badge.svg?branch=main)](https://github.com/sue445/rubocop-isucon/actions?query=workflow%3Atest)

## Installation

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

## Requires
### `libgda`
#### for Mac
```bash
brew install libgda
```

#### for Ubuntu, Debian
```bash
apt-get install libgda-5.0
```

#### for CentOS 7
```bash
yum install epel-release
yum --enablerepo=epel install libgda
```

#### for CentOS 8+
```bash
dnf install https://pkgs.dyn.su/el8/base/x86_64/raven-release-1.0-2.el8.noarch.rpm
dnf --enablerepo=raven install libgda
```

## Usage

Add this line to your application's `.rubocop.yml`

```yaml
require:
  - rubocop-isucon

inherit_gem:
  rubocop-isucon:
    # Disable default cops (except Performance cops)
    - "config/rubocop.yml"

Isucon/Mysql2:
  Database:
    adapter: mysql2
    host: # TODO: Fix this
    database: # TODO: Fix this
    username: isucon
    password: isucon
    encoding: utf8
    port: 3306
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/sue445/rubocop-isucon.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
