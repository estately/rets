# rets

* http://github.com/estately/rets

## DESCRIPTION:

[![Build Status](https://secure.travis-ci.org/estately/rets.png?branch=master)](http://travis-ci.org/estately/rets)
A pure-ruby library for fetching data from [RETS] servers.

If you're looking for a slick CLI interface check out [retscli](https://github.com/summera/retscli), which is an awesome tool for exploring metadata or learning about RETS.

[RETS]: http://www.rets.org

## REQUIREMENTS:

* [httpclient]
* [nokogiri]

[httpclient]: https://github.com/nahi/httpclient
[nokogiri]: http://nokogiri.org

## INSTALLATION:
```
gem install rets

# or add it to your Gemfile if using Bundler then run bundle install
gem 'rets'
```

## EXAMPLE USAGE:

We need work in this area! There are currently a few guideline examples in the `example` folder on connecting, fetching a property's data, and fetching a property's photos.

## Metadata caching

Metadata, which is loaded when a client is first started, can be slow
to fetch.  To avoid the cost of fetching metadata every time the
client is started, metadata can be cached.

To cache metadata, pass the :metadata_cache option to the client when
you start it.  The library comes with a predefined metadata cache that
persists the metadata to a file.  It is created with the path to which
the cached metadata should be written:

    metadata_cache = Rets::Metadata::FileCache.new("/tmp/metadata")

When you create the RETS client, pass it the metadata cache:

    client = Rets::Client.new(
      ...
      metadata_cache: metadata_cache
    )

If you want to persist to something other than a file, create your own
metadata cache object and pass it in.  It should have the same interface
as the built-in Metadata::FileCache class:

    class MyMetadataCache

      # Save the metadata.  Should yield an IO-like object to a block;
      # that block will serialize the metadata to that object.
      def save(&block)
      end

      # Load the metadata.  Should yield an IO-like object to a block;
      # that block will deserialize the metadata from that object and
      # return the metadata.  Returns the metadata, or nil if it could
      # not be loaded.
      def load(&block)
      end
      
    end

By default, the metadata is serialized using Marshal.  You may select
JSON or YAML instead, or define your own serialization mechanism, using the
:metadata_serializer option when you create the Rets::Client:

    client = Rets::Client.new(
      ...
      metadata_serializer: Rets::Metadata::JsonSerializer.new
    )

The built-in serializers are:

* Rets::Metadata::JsonSerializer
* Rets::Metadata::MarshalSerializer
* Rets::Metadata::YamlSerializer

To define your own serializer, create an object with this interface:

    class MySerializer

      # Serialize to a file.  The library reserves the right to change
      # the type or contents of o, so don't depend on it being
      # anything in particular.
      def save(file, o)
      end

      # Deserialize from a file.  If the metadata cannot be
      # deserialized, return nil.
      def load(file)
      end
      
    end

## LICENSE:

(The MIT License)

Copyright (c) 2011 Estately, Inc. <opensource@estately.com>

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
