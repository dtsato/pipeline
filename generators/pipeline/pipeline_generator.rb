class PipelineGenerator < Rails::Generator::Base
  
  def manifest
    record do |m|
      m.migration_template "pipeline_instances_migration.rb", 'db/migrate',
                           :migration_file_name => "create_pipeline_instances"
      m.migration_template "pipeline_stages_migration.rb", 'db/migrate',
                          :migration_file_name => "create_pipeline_stages"
    end
  end
  
end
