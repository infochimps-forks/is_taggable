
module IsTaggable
  module TagMethods
    def self.included base
      base.class_eval do
        class << self
          def find_or_initialize_with_name_like_and_kind(name, kind)
            with_name_like_and_kind(name, kind).first || new(:name => name, :kind => kind)
          end
        end

        has_many :taggings,  :dependent => :destroy

        validates_presence_of   :name
        validates_uniqueness_of :name, :scope => :kind

        named_scope :with_name_like_and_kind, lambda { |name, kind| { :conditions => ["name like ? AND kind = ?", name, kind] } }
        named_scope :of_kind,                 lambda { |kind|       { :conditions => {:kind => kind.to_s} } }

        def self.count_of kind
          of_kind(kind).count
        end

      end
    end
  end
end
