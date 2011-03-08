# path = File.expand_path(File.dirname(__FILE__))
# $LOAD_PATH << path unless $LOAD_PATH.include?(path)
# require_dependency File.expand_path(File.dirname(__FILE__))+'/tag'
require 'tagging'

module IsTaggable         
    
  class TagList < Array
    cattr_accessor :join_delimiter, :split_delimiter
    @@split_delimiter = /[, ]+/
    @@join_delimiter  = ","

    def split_and_sanitize str
      str.                       
        downcase.
        gsub(/[,\s]+/, ' ').
        gsub(/[^\w\s\:\-]+/, '').
        split(@@split_delimiter).
        collect(&:strip).
        reject(&:blank?).
        reject{|s| s =~ /^new\z/i}.
        uniq.
        sort
    end

    def initialize(list)
      list = list.is_a?(Array) ? list : split_and_sanitize(list)
      super
    end

    def to_s
      join(@@join_delimiter)
    end
  end

  module ActiveRecordExtension    
    
    def is_taggable(*kinds)
      has_many :taggings,  :dependent => :destroy
      has_many :tags,      :through   => :taggings
      class_inheritable_accessor :tag_kinds
      self.tag_kinds = kinds.map(&:to_s).map(&:singularize)
      self.tag_kinds << :tag if kinds.empty?

      include IsTaggable::TaggableMethods
    end
  end

  module TaggableMethods     
       
    #
    # Helper function for assembling a named_scope on taggables:
    # * given an integer, find tagged by that tag's ID
    # * given a string, look up by name (you're on your own for the kind)
    # * given a tag, look up by tag.name and kind.
    #
    def self.conditions_from_tag_and_kind tag, kind=nil
      conds = {}
      case tag
      when Tag    then conds.merge! :id => tag, :kind => tag.kind
      when String then conds[:name] = tag
      else             conds[:id]   = tag.to_i
      end
      conds[:kind] ||= kind unless kind.blank?
      conds
    end

    def self.included(klass)
      klass.class_eval do
        include IsTaggable::TaggableMethods::InstanceMethods
        has_many   :taggings, :as      => :taggable, :dependent => :destroy
        has_many   :tags,     :through => :taggings, :after_remove => :decrement_tag_taggings_count, :after_add => :increment_tag_taggings_count
        
        after_save :save_tags

        named_scope :with_tag,  lambda{|tag, *kind| kind = kind.first
          { :joins      =>  :tags,
            :conditions => {:tags => TaggableMethods.conditions_from_tag_and_kind(tag, kind)} } }

        tag_kinds.each do |k|
          define_method("#{k}_list")  { get_tag_list(k) }
          define_method("#{k}_list=") { |new_list| set_tag_list(k, new_list) }
        end
      end
    end

    module InstanceMethods
      def set_tag_list(kind, list)
        # taggings_will_change! if respond_to?(:taggings_will_change!)
        # tags_will_change!     if respond_to?(:tags_will_change!)
        tag_list = TagList.new(list)
        instance_variable_set(tag_list_name_for_kind(kind), tag_list)
      end

      def get_tag_list(kind)  
        set_tag_list(kind, tags.of_kind(kind).by_alpha.map(&:name)) if tag_list_instance_variable(kind).nil?
        tag_list_instance_variable(kind)
      end

    protected
      def tag_list_name_for_kind(kind)
        "@#{kind}_list"
      end

      def tag_list_instance_variable(kind)
        instance_variable_get(tag_list_name_for_kind(kind))
      end

      def save_tags
        # return true if taggings && (taggings.respond_to? :changed?) && (! taggings.changed?)
        tag_kinds.each do |tag_kind|
          delete_unused_tags(tag_kind)
          add_new_tags(tag_kind)
        end
        taggings.each(&:save)
      end

      def delete_unused_tags(tag_kind)         
        tags.of_kind(tag_kind).each { |t| tags.delete(t) unless get_tag_list(tag_kind).include?(t.name) }
      end

      def add_new_tags(tag_kind)
        tag_names = tags.of_kind(tag_kind).map(&:name)
        get_tag_list(tag_kind).each do |tag_name|
          tags << Tag.find_or_initialize_with_name_like_and_kind(tag_name, tag_kind) unless tag_names.include?(tag_name)
        end
      end
      
      def decrement_tag_taggings_count(tag)
        tag.decrement_taggings_count!(self.class.name.underscore) if tag.methods.include?("decrement_taggings_count!")
      end

      def increment_tag_taggings_count(tag)     
        tag.increment_taggings_count!(self.class.name.underscore) if tag.methods.include?("increment_taggings_count!")
      end
      
    end
  end
end

ActiveRecord::Base.send(:extend, IsTaggable::ActiveRecordExtension)