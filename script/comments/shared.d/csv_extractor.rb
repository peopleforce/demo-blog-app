# frozen_string_literal: true

class CsvExtractor
  attr_reader :file_path, :grouped_key

  def initialize(file_path:, grouped_key:)
    @file_path = file_path
    @grouped_key = grouped_key
  end

  def raw_data
    @raw_data ||= CSV.read(file_path, headers: true, header_converters: :symbol)
  end

  def grouped_data
    raw_data.map(&:to_h).group_by { |e| e[grouped_key] }
  end
end
