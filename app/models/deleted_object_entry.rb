# frozen_string_literal: true

class DeletedObjectEntry < ApplicationRecord
  belongs_to :owner, polymorphic: true
  belongs_to :object, polymorphic: true

  serialize :metadata
end
