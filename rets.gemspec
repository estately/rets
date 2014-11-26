# -*- encoding: utf-8 -*-
# stub: rets 0.6.0.20141126152224 ruby lib

Gem::Specification.new do |s|
  s.name = "rets"
  s.version = "0.6.0.20141126152224"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Estately, Inc. Open Source"]
  s.date = "2014-11-26"
  s.description = "[![Build Status](https://secure.travis-ci.org/estately/rets.png?branch=master)](http://travis-ci.org/estately/rets)\nA pure-ruby library for fetching data from [RETS] servers.\n\n[RETS]: http://www.rets.org"
  s.email = ["opensource@estately.com"]
  s.executables = ["rets"]
  s.extra_rdoc_files = ["CHANGELOG.md", "Manifest.txt", "README.md"]
  s.files = [".gemtest", "CHANGELOG.md", "Manifest.txt", "README.md", "Rakefile", "bin/rets", "lib/rets.rb", "lib/rets/client.rb", "lib/rets/client_progress_reporter.rb", "lib/rets/http_client.rb", "lib/rets/locking_http_client.rb", "lib/rets/measuring_http_client.rb", "lib/rets/metadata.rb", "lib/rets/metadata/containers.rb", "lib/rets/metadata/lookup_type.rb", "lib/rets/metadata/resource.rb", "lib/rets/metadata/rets_class.rb", "lib/rets/metadata/root.rb", "lib/rets/metadata/table.rb", "lib/rets/parser/compact.rb", "lib/rets/parser/multipart.rb", "test/fixtures.rb", "test/helper.rb", "test/test_client.rb", "test/test_locking_http_client.rb", "test/test_metadata.rb", "test/test_parser_compact.rb", "test/test_parser_multipart.rb", "test/vcr_cassettes/unauthorized_response.yml"]
  s.homepage = "http://github.com/estately/rets"
  s.rdoc_options = ["--main", "README.md"]
  s.rubyforge_project = "rets"
  s.rubygems_version = "2.2.0"
  s.summary = "[![Build Status](https://secure.travis-ci.org/estately/rets.png?branch=master)](http://travis-ci.org/estately/rets) A pure-ruby library for fetching data from [RETS] servers"
  s.test_files = ["test/test_client.rb", "test/test_locking_http_client.rb", "test/test_metadata.rb", "test/test_parser_compact.rb", "test/test_parser_multipart.rb"]

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<httpclient>, ["~> 2.3.0"])
      s.add_runtime_dependency(%q<nokogiri>, ["~> 1.5.2"])
      s.add_development_dependency(%q<rdoc>, ["~> 4.0"])
      s.add_development_dependency(%q<mocha>, ["~> 0.11.0"])
      s.add_development_dependency(%q<vcr>, ["~> 2.2.2"])
      s.add_development_dependency(%q<webmock>, ["~> 1.8.0"])
      s.add_development_dependency(%q<hoe>, ["~> 3.6"])
    else
      s.add_dependency(%q<httpclient>, ["~> 2.3.0"])
      s.add_dependency(%q<nokogiri>, ["~> 1.5.2"])
      s.add_dependency(%q<rdoc>, ["~> 4.0"])
      s.add_dependency(%q<mocha>, ["~> 0.11.0"])
      s.add_dependency(%q<vcr>, ["~> 2.2.2"])
      s.add_dependency(%q<webmock>, ["~> 1.8.0"])
      s.add_dependency(%q<hoe>, ["~> 3.6"])
    end
  else
    s.add_dependency(%q<httpclient>, ["~> 2.3.0"])
    s.add_dependency(%q<nokogiri>, ["~> 1.5.2"])
    s.add_dependency(%q<rdoc>, ["~> 4.0"])
    s.add_dependency(%q<mocha>, ["~> 0.11.0"])
    s.add_dependency(%q<vcr>, ["~> 2.2.2"])
    s.add_dependency(%q<webmock>, ["~> 1.8.0"])
    s.add_dependency(%q<hoe>, ["~> 3.6"])
  end
end
