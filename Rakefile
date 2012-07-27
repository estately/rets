require 'rubygems'
require 'hoe'

Hoe.plugin :git, :doofus
Hoe.plugin :travis
Hoe.plugin :gemspec

Hoe.spec 'rets' do
  developer 'Estately, Inc. Open Source', 'opensource@estately.com'

  extra_deps << [ "net-http-persistent", "~> 1.7" ]
  extra_deps << [ "nokogiri",            "~> 1.5.2" ]

  extra_dev_deps << [ "mocha", "~> 0.11.0" ]
  extra_dev_deps << [ "vcr", "~> 2.2.2" ]
  extra_dev_deps << [ "webmock", "~> 1.8.0" ]

  ### Use markdown for changelog and readme
  self.history_file = 'CHANGELOG.md'
  self.readme_file  = 'README.md'
end
