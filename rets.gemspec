# -*- encoding: utf-8 -*-
# stub: rets 0.11.2.20190930145017 ruby lib

Gem::Specification.new do |s|
  s.name = "rets".freeze
  s.version = "0.11.2.20190930145017"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Estately, Inc. Open Source".freeze]
  s.date = "2019-09-30"
  s.description = "[![Build Status](https://secure.travis-ci.org/estately/rets.png?branch=master)](http://travis-ci.org/estately/rets)\nA pure-ruby library for fetching data from [RETS] servers.\n\nIf you're looking for a slick CLI interface check out [retscli](https://github.com/summera/retscli), which is an awesome tool for exploring metadata or learning about RETS.\n\n[RETS]: http://www.rets.org".freeze
  s.email = ["opensource@estately.com".freeze]
  s.executables = ["rets".freeze]
  s.extra_rdoc_files = ["CHANGELOG.md".freeze, "Manifest.txt".freeze, "README.md".freeze]
  s.files = ["CHANGELOG.md".freeze, "Manifest.txt".freeze, "README.md".freeze, "Rakefile".freeze, "bin/rets".freeze, "example/connect.rb".freeze, "example/get-photos.rb".freeze, "example/get-property.rb".freeze, "lib/rets.rb".freeze, "lib/rets/client.rb".freeze, "lib/rets/client_progress_reporter.rb".freeze, "lib/rets/http_client.rb".freeze, "lib/rets/locking_http_client.rb".freeze, "lib/rets/measuring_http_client.rb".freeze, "lib/rets/metadata.rb".freeze, "lib/rets/metadata/caching.rb".freeze, "lib/rets/metadata/containers.rb".freeze, "lib/rets/metadata/file_cache.rb".freeze, "lib/rets/metadata/json_serializer.rb".freeze, "lib/rets/metadata/lookup_table.rb".freeze, "lib/rets/metadata/lookup_type.rb".freeze, "lib/rets/metadata/marshal_serializer.rb".freeze, "lib/rets/metadata/multi_lookup_table.rb".freeze, "lib/rets/metadata/null_cache.rb".freeze, "lib/rets/metadata/resource.rb".freeze, "lib/rets/metadata/rets_class.rb".freeze, "lib/rets/metadata/rets_object.rb".freeze, "lib/rets/metadata/root.rb".freeze, "lib/rets/metadata/table.rb".freeze, "lib/rets/metadata/table_factory.rb".freeze, "lib/rets/metadata/yaml_serializer.rb".freeze, "lib/rets/parser/compact.rb".freeze, "lib/rets/parser/error_checker.rb".freeze, "lib/rets/parser/multipart.rb".freeze, "test/fixtures.rb".freeze, "test/helper.rb".freeze, "test/test_caching.rb".freeze, "test/test_client.rb".freeze, "test/test_error_checker.rb".freeze, "test/test_file_cache.rb".freeze, "test/test_http_client.rb".freeze, "test/test_json_serializer.rb".freeze, "test/test_locking_http_client.rb".freeze, "test/test_marshal_serializer.rb".freeze, "test/test_metadata.rb".freeze, "test/test_metadata_class.rb".freeze, "test/test_metadata_lookup_table.rb".freeze, "test/test_metadata_lookup_type.rb".freeze, "test/test_metadata_multi_lookup_table.rb".freeze, "test/test_metadata_object.rb".freeze, "test/test_metadata_resource.rb".freeze, "test/test_metadata_root.rb".freeze, "test/test_metadata_table.rb".freeze, "test/test_metadata_table_factory.rb".freeze, "test/test_parser_compact.rb".freeze, "test/test_parser_multipart.rb".freeze, "test/test_yaml_serializer.rb".freeze, "test/vcr_cassettes/unauthorized_response.yml".freeze]
  s.homepage = "http://github.com/estately/rets".freeze
  s.licenses = ["MIT".freeze]
  s.rdoc_options = ["--main".freeze, "README.md".freeze]
  s.rubygems_version = "3.0.3".freeze
  s.summary = "[![Build Status](https://secure.travis-ci.org/estately/rets.png?branch=master)](http://travis-ci.org/estately/rets) A pure-ruby library for fetching data from [RETS] servers".freeze

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<httpclient>.freeze, ["~> 2.7"])
      s.add_runtime_dependency(%q<http-cookie>.freeze, ["~> 1.0.0"])
      s.add_runtime_dependency(%q<nokogiri>.freeze, ["~> 1.5"])
      s.add_development_dependency(%q<mocha>.freeze, ["~> 1.1.0"])
      s.add_development_dependency(%q<vcr>.freeze, ["~> 2.2"])
      s.add_development_dependency(%q<webmock>.freeze, ["~> 1.8"])
      s.add_development_dependency(%q<rdoc>.freeze, [">= 4.0", "< 7"])
      s.add_development_dependency(%q<hoe>.freeze, ["~> 3.18"])
    else
      s.add_dependency(%q<httpclient>.freeze, ["~> 2.7"])
      s.add_dependency(%q<http-cookie>.freeze, ["~> 1.0.0"])
      s.add_dependency(%q<nokogiri>.freeze, ["~> 1.5"])
      s.add_dependency(%q<mocha>.freeze, ["~> 1.1.0"])
      s.add_dependency(%q<vcr>.freeze, ["~> 2.2"])
      s.add_dependency(%q<webmock>.freeze, ["~> 1.8"])
      s.add_dependency(%q<rdoc>.freeze, [">= 4.0", "< 7"])
      s.add_dependency(%q<hoe>.freeze, ["~> 3.18"])
    end
  else
    s.add_dependency(%q<httpclient>.freeze, ["~> 2.7"])
    s.add_dependency(%q<http-cookie>.freeze, ["~> 1.0.0"])
    s.add_dependency(%q<nokogiri>.freeze, ["~> 1.5"])
    s.add_dependency(%q<mocha>.freeze, ["~> 1.1.0"])
    s.add_dependency(%q<vcr>.freeze, ["~> 2.2"])
    s.add_dependency(%q<webmock>.freeze, ["~> 1.8"])
    s.add_dependency(%q<rdoc>.freeze, [">= 4.0", "< 7"])
    s.add_dependency(%q<hoe>.freeze, ["~> 3.18"])
  end
end
