# -*- encoding: utf-8 -*-
# stub: rets 0.11.0.20170130173054 ruby lib

Gem::Specification.new do |s|
  s.name = "rets"
  s.version = "0.11.0.20170130173054"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Estately, Inc. Open Source"]
  s.date = "2017-01-30"
  s.description = "[![Build Status](https://secure.travis-ci.org/estately/rets.png?branch=master)](http://travis-ci.org/estately/rets)\nA pure-ruby library for fetching data from [RETS] servers.\n\nIf you're looking for a slick CLI interface check out [retscli](https://github.com/summera/retscli), which is an awesome tool for exploring metadata or learning about RETS.\n\n[RETS]: http://www.rets.org"
  s.email = ["opensource@estately.com"]
  s.executables = ["rets"]
  s.extra_rdoc_files = ["CHANGELOG.md", "Manifest.txt", "README.md"]
  s.files = ["CHANGELOG.md", "Manifest.txt", "README.md", "Rakefile", "bin/rets", "example/connect.rb", "example/get-photos.rb", "example/get-property.rb", "lib/rets.rb", "lib/rets/client.rb", "lib/rets/client_progress_reporter.rb", "lib/rets/http_client.rb", "lib/rets/locking_http_client.rb", "lib/rets/measuring_http_client.rb", "lib/rets/metadata.rb", "lib/rets/metadata/caching.rb", "lib/rets/metadata/containers.rb", "lib/rets/metadata/file_cache.rb", "lib/rets/metadata/json_serializer.rb", "lib/rets/metadata/lookup_table.rb", "lib/rets/metadata/lookup_type.rb", "lib/rets/metadata/marshal_serializer.rb", "lib/rets/metadata/multi_lookup_table.rb", "lib/rets/metadata/null_cache.rb", "lib/rets/metadata/resource.rb", "lib/rets/metadata/rets_class.rb", "lib/rets/metadata/rets_object.rb", "lib/rets/metadata/root.rb", "lib/rets/metadata/table.rb", "lib/rets/metadata/table_factory.rb", "lib/rets/metadata/yaml_serializer.rb", "lib/rets/parser/compact.rb", "lib/rets/parser/error_checker.rb", "lib/rets/parser/multipart.rb", "test/fixtures.rb", "test/helper.rb", "test/test_caching.rb", "test/test_client.rb", "test/test_error_checker.rb", "test/test_file_cache.rb", "test/test_http_client.rb", "test/test_json_serializer.rb", "test/test_locking_http_client.rb", "test/test_marshal_serializer.rb", "test/test_metadata.rb", "test/test_metadata_class.rb", "test/test_metadata_lookup_table.rb", "test/test_metadata_lookup_type.rb", "test/test_metadata_multi_lookup_table.rb", "test/test_metadata_object.rb", "test/test_metadata_resource.rb", "test/test_metadata_root.rb", "test/test_metadata_table.rb", "test/test_metadata_table_factory.rb", "test/test_parser_compact.rb", "test/test_parser_multipart.rb", "test/test_yaml_serializer.rb", "test/vcr_cassettes/unauthorized_response.yml"]
  s.homepage = "http://github.com/estately/rets"
  s.licenses = ["MIT"]
  s.rdoc_options = ["--main", "README.md"]
  s.rubygems_version = "2.5.1"
  s.summary = "[![Build Status](https://secure.travis-ci.org/estately/rets.png?branch=master)](http://travis-ci.org/estately/rets) A pure-ruby library for fetching data from [RETS] servers"

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<httpclient>, ["~> 2.7.0"])
      s.add_runtime_dependency(%q<http-cookie>, ["~> 1.0.0"])
      s.add_runtime_dependency(%q<nokogiri>, ["~> 1.5"])
      s.add_development_dependency(%q<rdoc>, ["~> 4.0"])
      s.add_development_dependency(%q<mocha>, ["~> 1.1.0"])
      s.add_development_dependency(%q<vcr>, ["~> 2.2"])
      s.add_development_dependency(%q<webmock>, ["~> 1.8"])
      s.add_development_dependency(%q<hoe>, ["~> 3.15"])
    else
      s.add_dependency(%q<httpclient>, ["~> 2.7.0"])
      s.add_dependency(%q<http-cookie>, ["~> 1.0.0"])
      s.add_dependency(%q<nokogiri>, ["~> 1.5"])
      s.add_dependency(%q<rdoc>, ["~> 4.0"])
      s.add_dependency(%q<mocha>, ["~> 1.1.0"])
      s.add_dependency(%q<vcr>, ["~> 2.2"])
      s.add_dependency(%q<webmock>, ["~> 1.8"])
      s.add_dependency(%q<hoe>, ["~> 3.15"])
    end
  else
    s.add_dependency(%q<httpclient>, ["~> 2.7.0"])
    s.add_dependency(%q<http-cookie>, ["~> 1.0.0"])
    s.add_dependency(%q<nokogiri>, ["~> 1.5"])
    s.add_dependency(%q<rdoc>, ["~> 4.0"])
    s.add_dependency(%q<mocha>, ["~> 1.1.0"])
    s.add_dependency(%q<vcr>, ["~> 2.2"])
    s.add_dependency(%q<webmock>, ["~> 1.8"])
    s.add_dependency(%q<hoe>, ["~> 3.15"])
  end
end
