$ ->
  $container = $("[data-behavior=organization-widgets]")
  if $container.length == 1
    $sortable = $container.find("[data-behavior=sortable]")
    
    # Drag
    $container.find("[data-behavior=draggable]").draggable(
      connectToSortable: $sortable
      revert: "invalid"
      helper: ->
        $(this).clone().css(width: $(this).outerWidth(), height: $(this).outerHeight())
    )
    
    # Drop
    $sortable.sortable(
      placeholder: "ui-state-highlight"
      axis: "y"
      connectWith: $sortable
      stop: (event, ui) ->
        item = ui.item
        
        if !item.attr("data-dropped")
          item.css(backgroundColor: "#eee")
          item.attr("data-dropped", true)
    )
    $sortable.disableSelection()
