module ApplicationHelper
  def pretty_time(time)
    if time > 24.hours.ago
      "#{distance_of_time_in_words_to_now(time)} #{t("common.ago")}"
    else
      time.to_formatted_s(:short)
    end
  end
  
  def breaking_word_wrap(text, *args)
    options = args.extract_options!
    unless args.blank?
      options[:line_width] = args[0] || 80
    end
      options.reverse_merge!(:line_width => 80)
      text = text.split(" ").collect do |word|
      word.length > options[:line_width] ? word.gsub(/(.{1,#{options[:line_width]}})/, "\\1 ") : word
    end * " "
      text.split("\n").collect do |line|
      line.length > options[:line_width] ? line.gsub(/(.{1,#{options[:line_width]}})(\s+|$)/, "\\1\n").strip : line
    end * "\n"
  end
end
