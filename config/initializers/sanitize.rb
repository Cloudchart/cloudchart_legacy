class Sanitize
  def self.clean_wysiwyg(html)
    # Config
    config = Sanitize::Config::RELAXED
    config[:remove_contents] = %w(script style)
    config[:elements] += %w(hr div)
    
    # Attributes
    config[:attributes]["div"] = %w(align style)
    
    # Clean
    self.clean(html, config)
  end
end
