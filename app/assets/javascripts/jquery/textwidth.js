(function($) {
  $.fn.textWidth = function(text){
    var org = $(this)
    var html = $('<span style="postion:absolute;width:auto;left:-9999px">' + text + '</span>');
    
    html.css("font-family", org.css("font-family"));
    html.css("font-size", org.css("font-size"));
    html.addClass(org.attr("class") + "-sample");
    
    $('body').append(html);
    var width = html.outerWidth();
    html.remove();
    return width;
  }
})(jQuery);