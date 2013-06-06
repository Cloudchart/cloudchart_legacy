$(document).on("click", "[data-behavior=organization-widgets] [data-behavior=widget-destroy]", (e) ->
  $(this).closest("[data-behavior=widget]").remove()
  false
)

$(document).on("click", "[data-behavior=organization-widgets] [data-behavior=save]", (e) ->
  $container = $(this).closest("[data-behavior=organization-widgets]")
  $button = $(this)
  
  data = {}
  $container.find("[data-behavior=sortable]").each(->
    area = $(this).attr("data-area")
    data[area] ?= []
    
    $(this).find("[data-behavior=widget]").each(->
      $widget = $(this)
      data[area].push(
        type: $widget.attr("data-type")
        values: $widget.find("form").serializeObject()
      )
    )
  )
  
  $button.addClass("disabled")
  $.ajax(url: $button.attr("data-action"), data: { widgets: data }, dataType: "json", type: "PUT")
    .always ->
      $button.removeClass("disabled")
      
    .error (xhr, status, error) ->
      console.error error
      
    .done (result) ->
      console.log result
  
  false
)

$(document).on("submit", "[data-behavior=organization-widgets] [data-behavior=widget] form", (e) ->
  $("[data-behavior=organization-widgets] [data-behavior=save]").trigger("click")
  false
)

$ ->
  $container = $("[data-behavior=organization-widgets]")
  if $container.length == 1
    $sortable = $container.find("[data-behavior=sortable]")
    $draggable = $container.find("[data-behavior=draggable]")
    
    # Render
    $container.find("[data-behavior=render]").each(->
      json = JSON.parse($(this).attr("data-json"))
      $(this).replaceWith(
        HandlebarsTemplates["organizations/widget"](
          type: json.type
          keys: JSON.parse($(this).attr("data-keys"))
          collections: JSON.parse($container.attr("data-collections"))
          values: json.values
        )
      )
    )
    
    # Drag
    $draggable.draggable(
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
        
        # Newly created item
        if !item.attr("data-dropped")
          console.log JSON.parse($container.attr("data-collections"))
          item.replaceWith(
            HandlebarsTemplates["organizations/widget"](
              type: item.attr("data-type")
              keys: JSON.parse(item.attr("data-keys"))
              collections: JSON.parse($container.attr("data-collections"))
              values: {}
            )
          )
        
    ).disableSelection()
