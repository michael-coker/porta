# frozen_string_literal: true

# Convention: name all missing models following this pattern +MissingModel::Missing<Model>+
class MissingModel
  include ActiveModel::Model
  include GlobalID::Identification

  attr_accessor :id

  def ==(other)
    id == other.try(:id)
  end

  class << self
    def find(id)
      new id: id.to_i
    end

    def model_name
      name = self.name.match(/MissingModel::Missing(\w+)$/)[1]
      ::ActiveModel::Name.new(self, nil, name)
    end

    def new_from_model_type(type:, id:)
      COLLECTION_MISSING_MODELS[type.to_s].new id: id
    end
  end

  COLLECTION_MISSING_MODELS = Hash.new(MissingModel)
  private_constant :COLLECTION_MISSING_MODELS

  # Create missing models subclasses
  %w[Application Cinstance Service Metric].each do |missing_subclass|
    missing_subclass_name = "Missing#{missing_subclass}"
    Object.const_set(missing_subclass_name, Class.new(MissingModel))
    COLLECTION_MISSING_MODELS.merge!(missing_subclass => missing_subclass_name.constantize)
  end
end

# TODO: FIX: /Users/marta/Devel/system/test/workers/delete_provider_stats_worker_test.rb:27: warning: toplevel constant MissingService referenced by MissingModel::MissingService
