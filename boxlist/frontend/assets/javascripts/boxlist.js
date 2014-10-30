$(document).ready(function() {

  boxlistHtml = function(array) {
    var html = '<table class="table">';
    var columns = ['container','subcontainer','contents','location'];
    html += '<thead><tr><th>Container</th><th>Contents</th><th>Location</th></tr></thead>'
    html += '<tbody>';
    for (i = 0; i < array.length; i++) {
      contents = [];
      html += '<tr>';
      var row = array[i];

      for (ii = 0; ii < 4; ii++) {
        var key = columns[ii];
        var cssClass = 'boxlist-' + key;
        if (!row[key]) {
          cssClass += ' blank';
        }
        if (key == 'subcontainer') {
          if (row[key]) {
            contents.push(row[key]);
          }
        }
        else {
          html += '<td class="' + cssClass + '">';
          if (key == 'contents') {
            contents.push(row[key]);
            html += contents.join('; ');
          }
          else {
            html += row[key] ? row[key] : '';
          }
          html += '</td>';
        }

      }

      html += '</tr>';
    }
    html += '</tbody></table>';
    return html;
  }

  $.fn.extend({

    loadBoxlist: function() {

      var container = $(this);
      var resourceId = $(container).attr('data-resource-id');
      var loadAlert = $(this).find('.boxlist-loading-notice');
      if (typeof resourceId != 'undefined') {

        console.log(resourceId);
        console.log(window.location);
        var dataUrl = window.location.origin + '/boxlist_data/' + resourceId;
        console.log(dataUrl);

        $.get( dataUrl, function( data ) {
          $(loadAlert).remove();
          $(container).html(boxlistHtml(data));
          console.log(data);
        });

      }

    }

  });


  $('#box-list-container').loadBoxlist();


});
