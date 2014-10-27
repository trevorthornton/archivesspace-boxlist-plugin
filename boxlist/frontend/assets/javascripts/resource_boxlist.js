$(document).ready(function() {

  var toolbarButtonAppended = false;

  attachToolbarButton = function(resource_id) {
    if (toolbarButtonAppended == false) {
      var recordToolbar = $('.record-toolbar');

      if (recordToolbar.length == 0) {
        $( document ).ajaxComplete(function() {
          console.log( "Triggered ajaxComplete handler." );
          attachToolbarButton(resource_id);
        });
      }

      else {
        var leftButtons = $(recordToolbar).find('.btn-group.pull-left');
        if (leftButtons.length == 0) {
          $( document ).ajaxComplete(function() {
            console.log( "Triggered ajaxComplete handler." );
            attachToolbarButton(resource_id);
          });
        } else {
          var boxlistButton = $('<a href="/boxlist/' + resource_id + '" class="btn btn-small">Box list</a>');
          $(leftButtons).append(boxlistButton);
          toolbarButtonAppended = true;
        }
      }
    }
  }

  if (window.location.pathname.match(/\/resources\/\d+/)) {
    var resource_id = window.location.pathname.replace(/\/resources\//,'');
    attachToolbarButton(resource_id);
  }


});
