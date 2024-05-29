# frozen_string_literal: true

require "term/ansicolor"

class CommentBuilder
  def self.call(data:)
    new(data).call
  end

  def call
    data.each do |slug, values|
      log_message "Handle post with slug: #{slug}"
      post = Post.find_by(slug: slug)
      if post
        try_to_create_comments_from(post, values)
      else
        log_error "Post with slug: #{slug} is not found"
        next
      end
    end

    puts yellow <<~INFO
      Count of created comments: #{@successfull_count}
      Count of the comments was not created: #{@fail_count}
      Prohibited keyword in the comments was not created:
      #{prohibited_keywords.uniq}
    INFO

    {
      successfull_count: @successfull_count,
      fail_count: @fail_count,
      prohibited_keywords: prohibited_keywords
    }
  end

  private

  attr_reader :data, :prohibited_keywords

  def initialize(data)
    @data = data
    @successfull_count = 0
    @fail_count = 0
    @prohibited_keywords = []
  end

  def log_message(message)
    puts green <<~MESSAGE
      #{message}
    MESSAGE
  end

  def log_error(error)
    puts red <<~ERROR
      #{error}
    ERROR
  end

  def try_to_create_comments_from(post, values)
    values.each do |value|
      comment = post.comments.new(content: value[:content], user_id: post.user_id)
      if comment.valid?
        comment.save
        @successfull_count += 1

        next
      end

      comment.errors.full_messages.each do |error|
        error_message = <<~STRING
          For post with slug #{post.slug} there is a validation error #{error}
        STRING
        log_error(error_message)

        prohibited_keywords << error[/keyword\:\s([A-Za-z]+)$/, 1]
      end

      @fail_count += 1
    end
  end
end
