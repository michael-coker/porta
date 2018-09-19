# frozen_string_literal: true

class DeletedObjectEntry < ApplicationRecord
  belongs_to :owner, polymorphic: true
  belongs_to :object, polymorphic: true

  [Service, Metric, Cinstance].each do |scoped_class|
    scope scoped_class.to_s.underscore.pluralize.to_sym, -> { where(object_type: scoped_class) }
  end

  serialize :metadata

  TTL = 3.months # TODO


  def object_instance(attributes: [])
    object_type.constantize.new do |obj_instance|
      obj_instance.id = object_id
      obj_instance.public_send("#{owner_type.to_s.underscore}=", owner)
      attributes.each { |attr_name| obj_instance.public_send("#{attr_name}=", metadata[attr_name.to_s]) }
    end
  end

  def missing_model_instance
    ::MissingModel.new_from_model_type(type: object_type, id: object_id)
  end
end
