class AssetUploader < CarrierWave::Uploader::Base
  include CarrierWave::RMagick
  
  storage :file
  
  def filename
    model.filename
  end
  
  def store_dir
    iteration = model.iteration.nil? ? PendingIteration.find(model.iteration_id) : model.iteration
    File.join('uploads', mounted_as.to_s, iteration.project.id, iteration.order.to_s)
  end
  
  version :thumb do
    process :crop_resized => [220, 144]
  end
  
  version :large do
    process :resize => [940, 10000]
  end
end