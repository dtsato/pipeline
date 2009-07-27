require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "pipeline"
    gem.summary  = "A Rails plugin/gem to run asynchronous processes in a configurable pipeline"
    gem.email = "danilo@dtsato.com"
    gem.homepage = "http://github.com/dtsato/pipeline"
    gem.authors = ["Danilo Sato"]
    gem.description = "Pipeline is a Rails plugin/gem to run asynchronous processes in a configurable pipeline."

    gem.has_rdoc = true
    gem.rdoc_options = ["--main", "README.rdoc", "--inline-source", "--line-numbers"]
    gem.extra_rdoc_files = ["README.rdoc"]

    gem.test_files = Dir['spec/**/*']
  end

rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: sudo gem install jeweler"
end

require 'spec/rake/spectask'
Spec::Rake::SpecTask.new(:spec) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.spec_files = FileList['spec/**/*_spec.rb']
  spec.spec_opts = ['--options', "\"spec/spec.opts\""]
end

Spec::Rake::SpecTask.new(:rcov) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov_opts = lambda do
    IO.readlines("spec/rcov.opts").map {|l| l.chomp.split " "}.flatten
  end
  spec.rcov = true
end


task :default => :spec

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  if File.exist?('VERSION.yml')
    config = YAML.load(File.read('VERSION.yml'))
    version = "#{config[:major]}.#{config[:minor]}.#{config[:patch]}"
  else
    version = ""
  end

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "pipeline #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

