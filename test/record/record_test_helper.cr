require "../test_helper"
require "../../src/record"
require "../../src/minitest"
require "secure_random"

module TestRecordCallbacks
  macro included
    def self.callbacks
      @@callbacks ||= [] of String
    end
  end

  {% for action in %w(save create update destroy) %}
    def before_{{ action.id }}
      self.class.callbacks << "#{ id }:before_{{ action.id }}"
    end

    def around_{{ action.id }}
      self.class.callbacks << "#{ id }:around_{{ action.id }}"
      yield
    end

    def after_{{ action.id }}
      self.class.callbacks << "#{ id }:after_{{ action.id }}"
    end
  {% end %}
end

class Post < Frost::Record
  include TestRecordCallbacks

  ifdef test_dependent_destroy
    has_many :comments, dependent: :destroy
  elsif test_dependent_delete
    has_many :comments, dependent: :delete_all
  elsif test_dependent_nullify
    has_many :comments, dependent: :nullify
  elsif test_dependent_exception
    has_many :comments, dependent: :exception
  else
    has_many :comments
  end

  def validate
    if title.blank?
      errors.add(:title, "Title is required")
    elsif title.to_s.size >= 100
      errors.add(:title, "Title must be less than 100 characters")
    end

    if body.blank?
      errors.add(:body, "Body is required")
    end
  end
end

class Comment < Frost::Record
  include TestRecordCallbacks

  belongs_to :post

  def validate
    #errors.add(:post_id, "Post is required") unless post
    errors.add(:email, "Email is required") if email.blank?
    errors.add(:body, "Body is required") if body.blank?
  end
end

class User < Frost::Record
  include TestRecordCallbacks

  ifdef test_dependent_destroy
    has_one :profile, dependent: :destroy, inverse_of: :user
  elsif test_dependent_delete
    has_one :profile, dependent: :delete, inverse_of: :user
  elsif test_dependent_nullify
    has_one :profile, dependent: :nullify, inverse_of: :user
  elsif test_dependent_exception
    has_one :profile, dependent: :exception, inverse_of: :user
  else
    has_one :profile, inverse_of: :user
  end

  def validate
    errors.add(:email, "Email is required") if email.blank?
  end
end

class Profile < Frost::Record
  include TestRecordCallbacks

  ifdef test_dependent_destroy
    belongs_to :user, dependent: :destroy
  elsif test_dependent_delete
    belongs_to :user, dependent: :delete
  else
    belongs_to :user
  end

  def validate
    errors.add(:nickname, "Nickname is required") if nickname.blank?
  end
end

class Minitest::Test
  fixtures "#{ __DIR__ }/../fixtures"
end
