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

    gem.test_files = Dir['spec/**/*'] + Dir['spec/*']
    
    gem.add_dependency('activerecord', '>= 2.0')
    gem.add_dependency('delayed_job', '>= 1.8.0')
    
    gem.rubyforge_project = "pipeline"
  end
  
  Jeweler::GemcutterTasks.new

rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: sudo gem install jeweler"
end

# These are new tasks
begin
  require 'rake/contrib/sshpublisher'
  namespace :rubyforge do

    desc "Release gem and RDoc documentation to RubyForge"
    task :release => ["rubyforge:release:gem", "rubyforge:release:docs"]

    namespace :release do
      desc "Publish RDoc to RubyForge."
      task :docs => [:rdoc] do
        config = YAML.load(
            File.read(File.expand_path('~/.rubyforge/user-config.yml'))
        )

        host = "#{config['username']}@rubyforge.org"
        remote_dir = "/var/www/gforge-projects/pipeline/"
        local_dir = 'rdoc'

        Rake::SshDirPublisher.new(host, remote_dir, local_dir).upload
      end
    end
  end
rescue LoadError
  puts "Rake SshDirPublisher is unavailable or your rubyforge environment is not configured."
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

begin
  require "synthesis/task"

  desc "Run Synthesis on specs"
  Synthesis::Task.new("spec:synthesis") do |t|
    t.adapter = :rspec
    t.pattern = 'spec/**/*_spec.rb'
    t.ignored = ['Pipeline::FakePipeline', 'Delayed::Job', 'SampleStage', 'Logger']
  end
rescue LoadError
  desc 'Synthesis rake task not available'
  task "spec:synthesis" do
    abort 'Synthesis rake task is not available. Be sure to install synthesis as a gem'
  end
end

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

task :default => :spec
