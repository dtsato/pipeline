require 'rubygems'
gem 'sqlite3-ruby'

ActiveRecord::Base.establish_connection(:adapter => 'sqlite3', :database => 'pipeline.sqlite')
ActiveRecord::Migration.verbose = false

ActiveRecord::Schema.define do

  create_table :delayed_jobs, :force => true do |table|
    table.integer  :priority, :default => 0
    table.integer  :attempts, :default => 0
    table.text     :handler
    table.string   :last_error
    table.datetime :run_at
    table.datetime :locked_at
    table.string   :locked_by
    table.datetime :failed_at
    table.timestamps
  end

  create_table :pipeline_instances, :force => true do |t|
    t.string :type
    t.string :status
    t.timestamps
  end

  create_table :pipeline_stages, :force => true do |t|
    t.references :pipeline_instance
    t.string  :type
    t.string  :name
    t.string  :status
    t.text    :message
    t.integer :retry_attempts, :default => 0
    t.timestamps
  end

end

at_exit do
  File.delete("pipeline.sqlite") if File.exists?("pipeline.sqlite")
end