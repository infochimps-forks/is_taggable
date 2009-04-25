require 'is_taggable'
require 'is_taggable/tag_methods'
ActiveSupport::Dependencies.load_once_paths.delete(File.expand_path(File.dirname(__FILE__))+'/lib')
