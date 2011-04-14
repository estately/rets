require 'rubygems'
require 'hoe'

Hoe.spec 'rets' do
  developer 'Estately, Inc. Open Source', 'opensource@estately.com'

  extra_deps << ["net-http-persistent", ">=0"]
  extra_deps << ["nokogiri", ">=0"]

  extra_dev_deps << ["mocha", ">=0"]

  ### Use markdown for changelog and readme
  self.history_file = 'CHANGELOG.md'
  self.readme_file  = 'README.md'
end
