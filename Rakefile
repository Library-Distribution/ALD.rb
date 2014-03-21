require 'zip'
require 'rake/testtask'
require 'rdoc/task'

task :default => [:archive, :test]

task :archive do
  Dir["test/data/archives/*.ald"].each { |f| File.delete f }

  Dir["test/data/archives/*"].select { |f| File.directory? f }.each do |dir|
    sh "cd #{dir} && zip -r ../#{File.basename(dir)}.zip *"
  end
end

Rake::TestTask.new do |t|
  t.libs << 'test'
end

RDoc::Task.new do |rdoc|
  rdoc.main = 'README.md'
  rdoc.rdoc_files.include('lib/**/*.rb')
  rdoc.rdoc_dir = 'docs'
end
