### 0.11.0 / NOT RELEASED YET

* fix: fix retry logging
* feature: allow retries to be configured for all query types in client settings
* feature: allow configrable wait time between retries
* feature: detect errors as error messages in a response body delivered with HTTP 200

### 0.10.1 / 2016-05-04

* fix: handle invalid codepoints in character references

### 0.10.0 / 2016-02-29

* fix: ensure cookie store exists #133
* feature: make cached capabilities case insensitive #136
* feature: add specific classes for each rets error #137
* feature: whitelist RETS search options #142
* feature: simplify metadata caching #134
* feature: use a SAX parser #98
* fix: save capabilities to avoid double logins #148
* feature: login on authorization error #155
* add basic support for DataDictionary feeds #156
* fix: count always returns a number #161
* feature: make lookup tables case insensitive #163
* feature: update to httpclient 2.7 #165
* fix: getObject now works with non-multipart responses #166
* fix: getObject works with multiple ids #167
* feature: store rets object metadata #168
* feature: add a code of conduct #171

### 0.9.0 / 2015-06-11

* feature: update to httpclient 2.6

### 0.8.1 / 2015-06-09

* fix: actually make the httpclient version more specific this time

### 0.8.0 / 2015-06-09

* feature: reduce memory usage on parsing metadata
* fix: correctly raise authorization error when given XHTML instead of XML
* fix: unescape HTML encoded responses
* fix: make httpclient version requirement more specific
* feature: add ability to print metadata to a file
* fix: remove Gemfile.lock from repository

### 0.7.0 / 2015-01-16

* feature: optionally treat No Records Found as not an error
* fix: update httpclient version, patches SSL vulnerabilities
* feature: work around bogus http status codes that don't agree with XML body

### 0.6.0 / 2014-11-26

* fix: fix spelling error that created misleading exceptions
* feature: track stats for http requests sent
* feature: raise an exception if the login action doesn't return an http 200 status
* feature: add better class description and more fields to print tree
* feature: support http proxies
* feature: customizable http timeouts
* feature: add logging http headers when in debug mode
* feature: strip invalid utf8 from responses before parsing
* fix: don't raise an exception on a 401 after logout
* fix: treat no matching records status without a count node as a zero count
* feature: add an option for loading custom ca_certs
* feature: remove invalid resource types from metadata
* feature: special case http 412
* feature: add max_retries option

### 0.5.1 / 2013-10-30

* fix: 0.5.0 was broken, fix gem Manifest to fix gem

### 0.5.0 / 2013-09-05

* feature: Allow client.count to get integer count
* feature: Allow for downcased capability names
* fix: Handle the rets element being empty
* feature: Instrument rets client with stats reporting
* feature: Add a locking client
* feature: Support Basic Authentication

### 0.4.0 / 2012-08-29

* fix: update authentication header to uri matches path

### 0.3.0 / 2012-07-31

* correctly handle digest authentication

### 0.3.0.rc.0 / 2012-07-26

* feature: significantly better handling of authorization failures

### 0.2.1 / 2012-04-20

* fix: better handling of malformed RETS responses

### 0.2.0 / 2012-04-20

* feature: Ruby 1.9 compatibility!

### 0.1.7 / 2012-04-05

* feature: key_field lookup for resources

### 0.1.6 / 2012-04-03

* fix: user_agent authentication

### 0.1.5 / 2012-03-17

* fix: retries raise error after too many failures
* fix: raise error for failed multipart object request
* fix: retries start with a clean slate, fixing authorization errors during retry

### 0.1.4 / 2012-03-12

* fix: an MLS uses lower case in RETS tag

### 0.1.3 / 2012-03-05

* fixes to support location=1 in getobject query

### 0.1.2 / 2012-02-17

* bugfix - check ReplyCode in login, retry on errors

### 0.1.1 / 2012-01-11

* bugfix - prevent infinite loop in login

# rets Changelog

### 0.1.0 / 2011-06-23

* First public release!

### 0.0.1 / 2011-03-24

* Project Created
