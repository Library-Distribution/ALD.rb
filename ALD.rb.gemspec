Gem::Specification.new do |s|
  s.name = 'ALD'
  s.version = '0.0.1'
  s.date = '2014-03-17'
  s.summary = 'Utility gem for the ALD protocol'
  s.description = 'A gem containing helpers for the ALD API, the ALD package format and ALD package definitions.'
  s.authors = ['maul.esel']
  s.files = ['lib/ALD.rb', 'lib/ALD/package.rb', 'lib/ALD/definition.rb', 'lib/ALD/package_generator.rb', 'lib/ALD/definition_generator.rb', 'lib/ALD/exceptions.rb', 'lib/ALD/schema.xsd']
  s.homepage = 'https://github.com/Library-Distribution/ALD.rb'
  s.license = 'MIT'

  s.add_runtime_dependency 'rubyzip', '~> 1.1'
  s.add_runtime_dependency 'nokogiri', '~> 1.6'
  s.add_development_dependency 'rake'
end