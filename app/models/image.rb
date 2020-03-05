# frozen_string_literal: true

# Image Model
class Image < ApplicationRecord
  belongs_to :user
  has_and_belongs_to_many :categories

  after_validation :clean_paperclip_errors

  default_scope { order(created_at: :desc) }

  has_attached_file :image,
                    # Store image files in specified path of AWS S3 bucket
                    path: 'images/:id/original/:filename'

  # Image attachment must be present, of an image content type,
  # and less than 5 megabytes in size
  validates_attachment_presence :image
  validates_attachment_content_type :image, content_type: %r{\Aimage/.*\z}
  validates_attachment_size :image, less_than: 5.megabytes, message: 'is too big to upload!'

  # Get rid of any duplicate paperclip errors
  def clean_paperclip_errors
    errors[:image].each do |error|
      errors[:image].delete(error) if error != "can't be blank"
    end
  end
end
