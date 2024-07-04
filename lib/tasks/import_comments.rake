# frozen_string_literal: true

namespace :import do
  desc 'Import comments from CSV'
  task comments: :environment do
    require 'csv'
    csv_file = Rails.root.join('comments.csv')

    unless File.exist?(csv_file)
      puts "CSV file not found: #{csv_file}"
      exit 1
    end

    puts "Starting import from #{csv_file}..."

    prohibited_keywords = Comment::PROHIBITED_KEYWORDS
    total_imported = 0

    ActiveRecord::Base.transaction do
      CSV.foreach(csv_file, headers: true) do |row|
        post_slug = row['Post Slug'].to_s.strip
        next if post_slug.blank?

        post = Post.find_by(slug: post_slug)

        unless post
          puts "Post with slug '#{post_slug}' not found."
          next
        end

        user_name  = row['User Name'].to_s.strip
        user_email = row['User Email'].to_s.strip

        user = User.find_or_create_by(email: user_email) do |u|
          u.name = user_name
        end

        content = row['Content'].to_s.strip
        sanitized_content = prohibited_keywords.reduce(content) do |text, keyword|
          text.gsub(/\b#{keyword}\b/i, '')
        end

        comment = post.comments.build(
          content: sanitized_content,
          user:
        )

        if comment.save
          total_imported += 1
          puts "Comment for post '#{post.slug}' saved successfully."
        else
          puts "Failed to save comment for post '#{post.slug}': #{comment.errors.full_messages.join(', ')}"
        end
      end
    end

    puts "Import finished. Total imported comments: #{total_imported}."
  rescue StandardError => e
    puts "Error during import: #{e.message}"
    raise ActiveRecord::Rollback
  end
end
