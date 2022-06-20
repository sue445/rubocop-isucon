require "benchmark/ips"
require "openssl"
require "securerandom"
require "shellwords"

def digest_with_shell_openssl(src)
  `printf "%s" #{Shellwords.shellescape(src)} | openssl dgst -sha512 | sed 's/^.*= //'`.strip
end

def digest_with_ruby_openssl(src)
  OpenSSL::Digest::SHA512.hexdigest(src)
end

SOURCE_TEXT = SecureRandom.alphanumeric(256)

Benchmark.ips do |x|
  x.report("digest_with_shell_openssl") do
    digest_with_shell_openssl(SOURCE_TEXT)
  end

  x.report("digest_with_ruby_openssl") do
    digest_with_ruby_openssl(SOURCE_TEXT)
  end
end
