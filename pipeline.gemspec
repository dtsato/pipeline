# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{pipeline}
  s.version = "0.0.8"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Danilo Sato"]
  s.date = %q{2009-08-20}
  s.description = %q{Pipeline is a Rails plugin/gem to run asynchronous processes in a configurable pipeline.}
  s.email = %q{danilo@dtsato.com}
  s.extra_rdoc_files = [
    "README.rdoc"
  ]
  s.files = [
    ".gitignore",
     "CHANGELOG",
     "LICENSE",
     "README.rdoc",
     "Rakefile",
     "TODO",
     "VERSION",
     "examples/auto_recoverable_pipeline.rb",
     "examples/cancelling_pipeline.rb",
     "examples/helper.rb",
     "examples/two_step_pipeline.rb",
     "examples/user_recoverable_pipeline.rb",
     "generators/pipeline/pipeline_generator.rb",
     "generators/pipeline/templates/migration.rb",
     "init.rb",
     "lib/pipeline.rb",
     "lib/pipeline/api_methods.rb",
     "lib/pipeline/base.rb",
     "lib/pipeline/core_ext/symbol_attribute.rb",
     "lib/pipeline/core_ext/transactional_attribute.rb",
     "lib/pipeline/errors.rb",
     "lib/pipeline/stage/base.rb",
     "pipeline.gemspec",
     "spec/database_integration_helper.rb",
     "spec/pipeline/api_methods_spec.rb",
     "spec/pipeline/base_spec.rb",
     "spec/pipeline/core_ext/symbol_attribute_spec.rb",
     "spec/pipeline/core_ext/transactional_attribute_spec.rb",
     "spec/pipeline/errors_spec.rb",
     "spec/pipeline/stage/base_spec.rb",
     "spec/rcov.opts",
     "spec/spec.opts",
     "spec/spec_helper.rb"
  ]
  s.homepage = %q{http://github.com/dtsato/pipeline}
  s.rdoc_options = ["--main", "README.rdoc", "--inline-source", "--line-numbers"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{pipeline}
  s.rubygems_version = %q{1.3.4}
  s.summary = %q{A Rails plugin/gem to run asynchronous processes in a configurable pipeline}
  s.test_files = [
    "spec/database_integration_helper.rb",
     "spec/pipeline",
     "spec/pipeline/api_methods_spec.rb",
     "spec/pipeline/base_spec.rb",
     "spec/pipeline/core_ext",
     "spec/pipeline/core_ext/symbol_attribute_spec.rb",
     "spec/pipeline/core_ext/transactional_attribute_spec.rb",
     "spec/pipeline/errors_spec.rb",
     "spec/pipeline/stage",
     "spec/pipeline/stage/base_spec.rb",
     "spec/rcov.opts",
     "spec/spec.opts",
     "spec/spec_helper.rb",
     "spec/database_integration_helper.rb",
     "spec/pipeline",
     "spec/rcov.opts",
     "spec/spec.opts",
     "spec/spec_helper.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<activerecord>, [">= 2.0"])
      s.add_runtime_dependency(%q<collectiveidea-delayed_job>, [">= 1.8.0"])
    else
      s.add_dependency(%q<activerecord>, [">= 2.0"])
      s.add_dependency(%q<collectiveidea-delayed_job>, [">= 1.8.0"])
    end
  else
    s.add_dependency(%q<activerecord>, [">= 2.0"])
    s.add_dependency(%q<collectiveidea-delayed_job>, [">= 1.8.0"])
  end
end
