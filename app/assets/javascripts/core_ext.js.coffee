RegExp.escape = (text) ->
  text.replace(/[-[\]{}()*+?.,\\^$|#\s]/g, "\\$&");

String.prototype.capitalize = ->
  this.charAt(0).toUpperCase() + this.slice(1)
