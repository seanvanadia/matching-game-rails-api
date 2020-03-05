# frozen_string_literal: true

# Category Title Serializer
class CategoryTitleSerializer < ActiveModel::Serializer
  attributes :id, :created_at, :title
end
