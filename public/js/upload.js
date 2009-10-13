$(document).ready(function() {
  $('#choose').uploadify({ 
    'uploader':  '/flash/uploadify.swf', 
    'script':    '/upload',
    'cancelImg': '/img/cancel.png',
    'hideButton': true,
    'wmode' : 'transparent',
    'width': $('#browse-link').width(),
    'height': $('#browse-link').height(),
  })
  
  pos = $('#browse-link').offset()
  
  //alert(pos.left + ' ' + pos.top)
  
  setTimeout(function() {
    $('#chooseUploader').css("top", pos.top)
                        .css("left", pos.left)
  }, 500)
  
  
});