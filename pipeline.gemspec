# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{pipeline}
  s.version = "0.0.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Danilo Sato"]
  s.date = %q{2009-07-27}
  s.description = %q{Pipeline is a Rails plugin/gem to run asynchronous processes in a configurable pipeline.}
  s.email = %q{danilo@dtsato.com}
  s.extra_rdoc_files = [
    "README.rdoc"
  ]
  s.files = [
    ".document",
     ".gitignore",
     "LICENSE",
     "README.rdoc",
     "Rakefile",
     "VERSION",
     "lib/pipeline.rb",
     "spec/pipeline_spec.rb",
     "spec/spec_helper.rb"
  ]
  s.homepage = %q{http://github.com/dtsato/pipeline}
  s.rdoc_options = ["--main", "README.rdoc", "--inline-source", "--line-numbers"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.4}
  s.summary = %q{A Rails plugin/gem to run asynchronous processes in a configurable pipeline}
  s.test_files = [
    "spec/pipeline_spec.rb",
     "spec/spec_helper.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
