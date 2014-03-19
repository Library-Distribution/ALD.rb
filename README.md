# ALD.rb

[![Coverage Status](https://coveralls.io/repos/Library-Distribution/ALD.rb/badge.png?branch=master)](https://coveralls.io/r/Library-Distribution/ALD.rb?branch=master)
[![Build Status](https://travis-ci.org/Library-Distribution/ALD.rb.png?branch=master)](https://travis-ci.org/Library-Distribution/ALD.rb)
[![Code Climate](https://codeclimate.com/github/Library-Distribution/ALD.rb.png)](https://codeclimate.com/github/Library-Distribution/ALD.rb)
[![Gemnasium](https://gemnasium.com/Library-Distribution/ALD.rb.png)](https://gemnasium.com/Library-Distribution/ALD.rb)

## About
This is an in-progress attempt at a Ruby library for the ALD protocol, for both client-side and server-side use.

It is organized as a Ruby gem, and is available [via RubyGems](http://rubygems.org/gems/ALD).

## Planned components
### Managing ALD packages
* `ALD::Package` - read an ALD package file and extract information
* `ALD::Package::Generator` - create a new ALD package
* `ALD::Definition` - read an ALD package definition and extract information
* `ALD::Definition::Generator` - dynamically create a package definition

### Accessing the ALD API
* `ALD::API` and nested classes - given a root URL, make requests to an ALD server and return the obtained information

## Getting started
Install the gem with

```
gem install ALD
```

and require it:
```ruby
require 'ALD'
```

### Open an ALD package
```ruby
require 'ALD/package'

package = ALD::Package.open('path/to/file.zip')
puts "#{package.definition.name} v#{package.definition.version} (#{package.definition.id}}) is now loaded."
```

### Read a definition file
```ruby
require 'ALD/definition'

definition = ALD::Definition.new('path/to/definition.xml')
puts "#{definition.name} v#{definition.version}"

puts "Summary: '#{definition.summary}'"

puts "Authors:"
definition.authors.each { |author| puts "\t- #{author['name']}" }

puts "Tagged as:"
definition.tags.each { |tag| puts "\t- #{tag}" }
```

### Create a new definition
TBD (unimplemented)

### Create a new package
TBD (unimplemented)

### Note:
The `ALD::Package` and `ALD::Definition` classes are read-only. To modify a package or definition, open them using the mentioned classes and
call `ALD::Package::Generator.from_package` or `ALD::Definition::Generator.from_definition` to get a `::Generator` instance which you can then
modify. Save your changes using `::Generator#generate!`.

## Dependencies
* [rubyzip](https://github.com/rubyzip/rubyzip) to extract information from the ALD packages
* [nokogiri](http://nokogiri.org/) to effectively parse the package definitions

## Status
So far, development concentrates on the package management part. It is however far from ready.

## Contributions...
... are highly welcomed. I'm happy to accept any helpful pull requests.