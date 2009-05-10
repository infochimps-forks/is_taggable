class IsTaggableMigrationGenerator < Rails::Generator::Base
  def manifest
    record do |m|
      m.migration_template 'migration.rb', 'db/migrate', :migration_file_name => 'is_taggable_migration'
      m.directory 'config/initializers/'
      m.file      'config/initializers/is_taggable_constraints.rb', 'config/initializers/is_taggable_constraints.rb'
    end
  end

  def banner
    "\nUsage: script/generate is_taggable_migration.\n\n"
  end

end
