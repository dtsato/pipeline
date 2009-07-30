class PipelineGenerator < Rails::Generator::Base
  
  def manifest
    record do |m|
      m.migration_template "migration.rb", 'db/migrate',
                           :migration_file_name => "create_pipeline_instances_and_stages"
    end
  end
  
end
