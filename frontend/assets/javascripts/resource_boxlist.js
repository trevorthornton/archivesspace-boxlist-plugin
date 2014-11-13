$(document).ready(function() {

  $.fn.extend({

    addToolbarButton: function() {

      addBtn = function(resource_id) {
        if ((toobarBtnAdded == false) || ($('.box-list-btn').length == 0)) {
          var container = $('.record-toolbar .btn-group.pull-left');
          var containerLoaded = ($(container).length > 0) ? true : false;

          if (containerLoaded) {
            var boxlistButton = $('<a href="/boxlist/' + resource_id + '" class="btn btn-small box-list-btn">Box list</a>');
            $(container).append(boxlistButton);
            toobarBtnAdded = true;
          } else {
            $( document ).ajaxComplete(function() {
              $(document).addToolbarButton();
            });
          }
        }
      }

      if (window.location.pathname.match(/\/resources\/\d+/)) {
        var resource_id = window.location.pathname.replace(/\/resources\//,'');
        addBtn(resource_id);
      }
    }
  });

  var toobarBtnAdded = false;
  $(document).addToolbarButton();

});
