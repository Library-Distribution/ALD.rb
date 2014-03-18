# ALD.rb

[![Coverage Status](https://coveralls.io/repos/Library-Distribution/ALD.rb/badge.png?branch=master)](https://coveralls.io/r/Library-Distribution/ALD.rb?branch=master)
[![Build Status](https://travis-ci.org/Library-Distribution/ALD.rb.png?branch=master)](https://travis-ci.org/Library-Distribution/ALD.rb)
[![Code Climate](https://codeclimate.com/github/Library-Distribution/ALD.rb.png)](https://codeclimate.com/github/Library-Distribution/ALD.rb)
[![Gemnasium](https://gemnasium.com/Library-Distribution/ALD.rb.png)](https://gemnasium.com/Library-Distribution/ALD.rb)

## About
This is an in-progress attempt at a Ruby library for the ALD protocol, for both client-side and server-side use.

It is organized as a Ruby gem, but not yet ready to be released.

## Planned components
### Managing ALD packages
* `ALD::Package` - read an ALD package file and extract information
* `ALD::Package::Generator` - create a new ALD package
* `ALD::Definition` - read an ALD package definition and extract information
* `ALD::Definition::Generator` - dynamically create a package definition

### Accessing the ALD API
* `ALD::API` and nested classes - given a root URL, make requests to an ALD server and return the obtained information

## Status
So far, development concentrates on the package management part. It is however far from ready.

## Contributions...
... are highly welcomed. I'm happy to accept any helpful pull requests.