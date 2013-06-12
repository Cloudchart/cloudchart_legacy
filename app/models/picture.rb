class Picture
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Paperclip
  store_in collection: "pictures"
  
  # Relations
  belongs_to :organization, inverse_of: :uploads
  
  # Picture
  has_mongoid_attached_file :picture,
    styles: { preview: ["500x", :png] }
  
  # Representation
  def serializable_hash(options)
    super (options || {}).merge(
      except: [
        :_id,
        :picture_content_type, :picture_file_name, :picture_file_size, :picture_updated_at
      ],
      methods: [:id, :preview_url]
    )
  end
  
  def preview_url
    self.picture.url(:preview)
  end
end
