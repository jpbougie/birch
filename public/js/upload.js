$(document).ready(function() {
  $('#choose').uploadify({ 
    'uploader':  '/flash/uploadify.swf', 
    'script':    '/upload',
    'fileDataName': 'asset',
    'cancelImg': '/img/cancel.png',
    'hideButton': true,
    'multi': true,
    'queueID': 'queue',
    'wmode' : 'transparent',
    'width': $('#choose').width(),
    'height': $('#choose').height(),
    'onComplete': Upload.onComplete,
    'onSelectOnce': Upload.onSelectOnce,
    'onCancel': Upload.onCancel,
  })
    
  
  setTimeout(function() {
    $('#choose').css("display", "inline")
    $('#chooseUploader').css("top", "0")
    $('#chooseUploader').css("left", "0")    
  }, 1)
  
  
  $('#launch-upload').click(function() {
    if(('#queue .uploadifyQueueItem').length > 0) {
      $('#choose').uploadifyUpload()
    }
    
    return false;
  })
  
  
  $("#create-project").click(function() {
    $("#describe-form form").submit()
  })
});

Upload = {}

Upload.project = null

Upload.onComplete = function(event, queueId, fileObj, response, data) {
  
  eval("resp = " + response)
    
  Upload.project = resp.project_id
  $('#prid').attr("value", Upload.project)
  
  $('#choose').uploadifySettings('scriptData', {'project': Upload.project})
  
  return true
}

Upload.onSelectOnce = function(event, data) {
  if(data.fileCount > 0) {
    $("#queue").show()
    $("#launch-upload").removeClass("disabled")
  }
}

Upload.onCancel = function(event, queueID, fileObj, data) {
   if(data.fileCount == 0) {
     $("#queue").hide()
     $("#launch-upload").addClass("disabled")
   }
  
  return true
}

Upload.onAllComplete = function(event, uploadObj) {
  return true
}