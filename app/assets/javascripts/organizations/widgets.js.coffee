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
      location.href = result.redirect_to
  
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
    
    # Sticky widgets
    $widgets = $("[data-behavior=widgets]")
    $widgets.sticky(topSpacing: 20)
    $widgets.css(width: $widgets.outerWidth())
    
    # Render
    $container.find("[data-behavior=render]").each(->
      area = $(this).closest("[data-area]").attr("data-area")
      json = JSON.parse($(this).attr("data-json"))
      config = JSON.parse($(this).attr("data-config"))
      collections = JSON.parse($container.attr("data-collections"))
      
      $(this).replaceWith(
        HandlebarsTemplates["organizations/widget"](
          area: area
          type: json.type
          config: config
          collections: collections
          values: json.values
        )
      )
    )
    $container.find("textarea").autosize()
    
    # Drag
    $draggable.draggable(
      connectToSortable: $sortable
      revert: "invalid"
      helper: ->
        $(this).clone().css(width: $(this).outerWidth(), height: $(this).outerHeight())
      start: ->
        $(this).addClass("ui-draggable-active")
      stop: ->
        $(this).removeClass("ui-draggable-active")
    )
    
    # Drop
    $sortable.sortable(
      placeholder: "ui-sortable-placeholder"
      axis: "y"
      connectWith: $sortable
      
      over: (event, ui) ->
        # return if ui.helper.hasClass("ui-draggable-over")
        
        # Adjust placeholder
        config = JSON.parse(ui.helper.attr("data-config"))
        placeholder = $(this).find(".ui-sortable-placeholder")
        placeholder.html("<i class='icon-#{config.icon}'></i> #{I18n.t("organizations.edit.widget_placeholder", type: ui.helper.attr("data-type").capitalize())}")
        placeholder.addClass(ui.helper.attr("data-type"))
        
        ui.helper.addClass("ui-draggable-over")
      
      out: (event, ui) ->
        ui.helper.removeClass("ui-draggable-over") if ui.helper
      
      receive: (event, ui) ->
        item = ui.item
        type = item.attr("data-type")
        config = JSON.parse(item.attr("data-config"))
        
        # Unique item
        if config.unique
          # console.log "receive", $(this).find("[data-type=#{type}]").length
          if $(this).find("[data-type=#{type}]").length > 1
            if ui.sender && ui.sender.hasClass("ui-sortable")
              $(ui.sender).sortable("cancel")
        
      stop: (event, ui) ->
        item = ui.item
        
        # Newly created item
        if !item.attr("data-dropped")
          area = $(this).closest("[data-area]").attr("data-area")
          type = item.attr("data-type")
          config = JSON.parse(item.attr("data-config"))
          collections = JSON.parse($container.attr("data-collections"))
          
          # Unique item
          if config.unique
            # console.log "stop", $(this).find("[data-type=#{type}]").length
            if $(this).find("[data-type=#{type}]").length > 1
              item.remove()
              return true
          
          item.replaceWith(
            HandlebarsTemplates["organizations/widget"](
              area: area
              type: type
              config: config
              collections: collections
              values: {}
            )
          )
          item.find("textarea").autosize()
        
    ).disableSelection()
