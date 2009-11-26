require 'dam'

Dam.activity :comment_posted do
  user do
    { "name" => params[:comment].user.name, "id" => params[:comment].user_id }
  end
  
  action "post"
  
  published { params[:comment].created_at.to_s }
  
  comment do
    { "body" => params[:comment].body, "id" => params[:comment].id }
  end
  
  project do
    { "id" => params[:project].id }
  end
  
  text { "#{params[:comment].user.name} left a <a href=\"#{params[:url]}\">comment</a>."}
  
end

Dam.activity :alternative_liked do
  user do
    { "name" => params[:user].name, "id" => params[:user].id }
  end
  
  action "likes"
  
  published { params[:created_at] }
  
  alternative { params[:alternative].id }
  
  text { "#{params[:user].name} likes this."}
end

Dam.activity :annotation_created do
  user do
    { "name" => params[:annotation].user.name, "id" => params[:annotation].user.id }
  end
  
  action "annotated"
  
  alternative { params[:annotation].alternative.id }
  
  annotation { params[:annotation].id }
  
  text { "#{params[:annotation].user.name} has annotated this picture."}
  
end
  

Dam::stream "user/:user" do
  accepts :user => {"id" => params[:user] }
end

Dam::stream "project/:project" do
  accepts :project => { "id" => params[:project] }
end

Dam.stream "iteration/:iteration" do
  accepts :iteration => {"id" => params[:iteration] }
end

Dam.stream "alternative/:alternative" do
  accepts :alternative => params[:alternative]
end