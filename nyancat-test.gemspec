require File.expand_path('../lib/nyancat-test/version', __FILE__)

Gem::Specification.new do |gem|
  gem.name          = 'nyancat-test'
  gem.version       = Nyancat::Test::VERSION
  gem.authors       = ['Craig Little', 'Noel Dellofano']
  gem.email         = ['craiglttl@gmail.com', 'noel@zendesk.com']
  gem.description   = %q{Nyan Cat for MiniTest}
  gem.summary       = %q{Nyan cat goodness for the testing masses.}
  gem.homepage      = 'https://github.com/craiglittle/nyancat-test'

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ['lib']
end
