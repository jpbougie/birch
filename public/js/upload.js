$(document).ready(function() {
  $('#choose').uploadify({ 
    'uploader':  '/flash/uploadify.swf', 
    'script':    '/upload',
    'fileDataName': 'asset',
    'cancelImg': '/img/cancel.png',
    'hideButton': true,
    'multi': true,
    'wmode' : 'transparent',
    'width': $('#browse-link').width(),
    'height': $('#browse-link').height(),
    'onComplete': Upload.onComplete,
  })
  
  pos = $('#browse-link').offset()
  
  
  setTimeout(function() {
    $('#chooseUploader').css("top", pos.top)
                        .css("left", pos.left)
  }, 500)
  
  
  $('#launch-upload').click(function() {
    $('#choose').uploadifyUpload()
    return false;
  })
});

Upload = {}

Upload.project = null

Upload.onComplete = function(event, queueId, fileObj, response, data) {
  
  eval("resp = " + response)
    
  Upload.project = resp.project_id
  
  $('#choose').uploadifySettings('scriptData', {'project': Upload.project})
  
  return true
}