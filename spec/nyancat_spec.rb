$: << File.expand_path('../../lib', __FILE__)

require 'bundler'
Bundler.setup

require 'minitest/autorun'
require 'nyancat-test'

class TestClass
end

describe TestClass do
  80.times { it 'blah' do sleep 0.02; end }
  4.times { it 'blah' do raise Exception end }
  8.times { it 'blah' do sleep 0.02; assert false end }
  8.times { it 'blah' }
end
