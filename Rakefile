require 'rubygems'
require 'hoe'
require 'rake/testtask'

Hoe.plugin :git, :doofus
Hoe.plugin :travis
Hoe.plugin :gemspec

Hoe.spec 'rets' do
  developer 'Estately, Inc. Open Source', 'opensource@estately.com'

  extra_deps << [ "httpclient", "~> 2.7.0" ]
  extra_deps << [ "http-cookie", "~> 1.0.0" ]
  extra_deps << [ "nokogiri",   "~> 1.5" ]

  extra_dev_deps << [ "mocha", "~> 1.1.0" ]
  extra_dev_deps << [ "vcr", "~> 2.2" ]
  extra_dev_deps << [ "webmock", "~> 1.8" ]

  ### Use markdown for changelog and readme
  self.history_file = 'CHANGELOG.md'
  self.readme_file  = 'README.md'
end


Rake::TestTask.new do |t|
  t.pattern = "test/test_*.rb"
end
