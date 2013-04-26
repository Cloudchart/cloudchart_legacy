//= require core_ext
//= require jquery
//= require jquery_ujs
//= require jquery.ui.draggable
//= require jquery.ui.droppable
//= require handlebars
//= require twitter/bootstrap
//= require bootstrap
//= require plugins
//= require cc
//= require_tree ./templates

$ ->
  # Init PersonsView
  container = $("[data-behavior=persons-view]")
  if container.length == 1
    container.data("personsView", new cc.PersonsView(
      container: container
    ))
    
    # Drop
    $("[data-behavior=droppable]").droppable(
      hoverClass: "active"
      drop: (event, ui) ->
        $this = ui.draggable
        identifier = $this.attr("data-identifier")
        picture = $this.attr("data-picture")
        
        node = $('<div class="img"></div>').appendTo(this)
        node.css(backgroundImage: "url(#{picture})") if picture
        
        # Mark person as used
        container.data("personsView").update(id: identifier, used: true, ->
          alert("Used!")
        )
    )
