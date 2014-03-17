require 'zip'
require 'rake/testtask'

Rake::TestTask.new do |t|
  t.libs << 'test'
end

task :default => [:archive, :test]

task :archive do
  Dir["test/data/archives*.ald"].each { |f| File.delete f }

  Dir["test/data/archives/*"].select { |f| File.directory? f }.each do |dir|
    sh "zip -r #{dir}.ald #{dir}"
  end
end