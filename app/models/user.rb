# frozen_string_literal: true

# User Model
class User < ApplicationRecord
  has_many :categories
  has_many :images
  has_one :win_total

  # Users are token authenticatable
  acts_as_token_authenticatable

  # Permit devise authentication and validation
  devise :database_authenticatable, :registerable, :trackable, :validatable,
         # Passwords must be between 8 and 30 characters
         password_length: 8..30,

         # Email addresses have standard validations,
         # including a maximum of 254 characters
         email_regexp: /(?=.{,254}$)\A[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}\z/i

  # Passwords must contain a letter and a number
  validate :password_complexity
  def password_complexity
    return unless password.present?
    return if password.match(/(?=.*[A-Z])(?=.*[0-9])/i)

    errors.add :password, 'must contain a letter and a number'
  end
end
