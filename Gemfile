source :rubygems

gem 'rake'
gem 'sinatra'
gem 'haml'
gem 'nokogiri'
gem 'mechanize'
gem 'mongoid',  '2.0'
gem 'bson_ext', '~>1.3'
#gem 'ruby-debug'

group :test do
  gem 'rspec'
end
# Add your own local bundler stuff
local_gemfile = File.dirname(__FILE__) + "/.Gemfile"
instance_eval File.read local_gemfile if File.exists? local_gemfile

