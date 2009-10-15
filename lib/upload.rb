class AssetUploader < CarrierWave::Uploader::Base
  include CarrierWave::RMagick
  
  storage :file
  
  def filename
    model.name
  end
  
  def store_dir
    File.join('uploads', mounted_as.to_s, model.iteration.project.id, model.iteration.order.to_s)
  end
  
  version :thumb do
    process :crop_resized => [150, 150]
  end
end