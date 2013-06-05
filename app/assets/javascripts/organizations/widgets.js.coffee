$ ->
  $container = $("[data-behavior=organization-widgets]")
  if $container.length == 1
    # Drag
    $container.find("[data-behavior=draggable]").draggable(
      helper: ->
        $(this).clone().css(width: $(this).outerWidth(), height: $(this).outerHeight())
      # appendTo: "body"
    )
    
    # Drop
    $container.find("[data-behavior=droppable]").droppable(
      hoverClass: "active"
      drop: (event, ui) ->
        $this = ui.draggable
        console.log $this
    )
