root           = @
@organization ?= {}
scope          = @organization

class Widget
  @collections = {}
  
  constructor: (attributes = {}) ->
    @container = attributes.container
    
    @area = @container.closest("[data-area]").attr("data-area")
    @config = JSON.parse(@container.attr("data-config"))
    @index = @container.index()
    
    # Existent
    if @container.attr("data-json")
      json = JSON.parse(@container.attr("data-json"))
      @type = json.type
      @values = json.values
      
    # New
    else
      @type = @container.attr("data-type")
      @values = {}
    
    @container = @container.replaceWithPush(
      HandlebarsTemplates["organizations/widget"](
        area: @area
        type: @type
        index: @index
        config: @config
        collections: @constructor.collections
        values: @values
      )
    )
    
    # Init plugins
    @container.find("textarea").autosize()
    
    # Init specific
    @["init_#{@type}"]() if @["init_#{@type}"]
    
    # Set widget
    @container.data("widget", this)
  
  # Init methods
  init_text: ->
    $editor = @container.find("[data-behavior=editor]")
    $toolbar = @container.find("[data-behavior=toolbar]")
    
    # Unescape
    $editor.html($editor.text())
    $editor.trigger("change")
    
    $toolbar.find("[data-toggle]").on("click", ->
      toggle = $(this).attr("data-toggle")
      $toolbar.find(".#{toggle}").toggle()
    )
    
    $toolbar.find("input").on("keydown", (e) ->
      if e.keyCode == 13
        $(this).trigger("change")
        return false
    )
    
    $editor.wysiwyg(
      toolbarSelector: "##{$toolbar.attr("id")}"
      activeToolbarClass: "active"
    )
    $editor.on("mouseup keyup", ->
      setTimeout(=>
        sel = window.getSelection()
        
        # Calculate offset for toolbar
        offset = 
          top: $editor.offset().top
          left: $editor.offset().left - parseInt($editor.parent().css("paddingLeft"))
        
        text = ""
        range = null
        rects = null
        
        if sel.getRangeAt && sel.rangeCount
          range = sel.getRangeAt(0).cloneRange()
          text = range.toString()
        
        if range && range.getClientRects
          # range.collapse(true)
          rects = range.getClientRects()[0]
        
        if rects && text != ""
          $toolbar.css(
            top: rects.top - offset.top - $toolbar.outerHeight()*1.5
            left: rects.left - offset.left + rects.width/2 - $toolbar.outerWidth()/2
          )
          $toolbar.fadeIn("fast")
        else
          $toolbar.fadeOut("fast", ->
            $toolbar.find(".link").hide()
          )
      , 50)
    )
  
  init_chart: ->
    if @values.id
      chart = $.grep(@constructor.collections.charts, (chart) => chart.id == @values.id)
      @select_chart(chart[0]) if chart
  
  init_picture: ->
    if @values.url
      @select_picture(@values.url)
    
    # Picture upload
    self = this
    $file = @container.find("[data-behavior=picture-upload]")
    $file.fileupload(
      url: $("[data-behavior=organization-edit]").attr("action")
      type: "PUT"
      dataType: "json"
      formData: {}
      done: (e, data) ->
        self.select_picture(data.result.preview_url)
    )
  
  # Type methods
  select_chart: (chart) ->
    @container.find("[data-behavior=id]").val(chart.id)
    @container.find("[data-behavior=title]").html(chart.title)
    @container.find("[data-behavior=picture]").attr("src", chart.picture_url)
  
  select_picture: (url) ->
    @container.find("[data-behavior=url]").val(url)
    @container.addClass("active")
    @container.find("[data-behavior=selected] img").attr("src", url)

# Add to scope
$.extend scope,
  Widget: Widget

# Widget actions
$(document).on("click", "[data-behavior=organization-widgets] [data-behavior=widget-destroy]", (e) ->
  $(this).closest("[data-behavior=widget]").remove()
  false
)

## Picture
$(document).on("click", "[data-behavior=organization-widgets] [data-type=picture] [data-behavior=actions]", (e) ->
  $(this).closest("[data-behavior=widget]").find("[data-behavior=picture-upload]").click()
)

## Chart
$(document).on("click", "[data-behavior=organization-widgets] [data-behavior=browse-charts]", (e) ->
  $modal = $("[data-behavior=organization-widgets] [data-behavior=modal]")
  $modal.find("[data-behavior=title]").html(I18n.t("organizations.edit.widgets.chart.all_charts"))
  $modal.find("[data-behavior=body]").html(
    HandlebarsTemplates["organizations/charts"](
      charts: Widget.collections.charts
    )
  )
  
  widget = $(this).closest("[data-behavior=widget]").data("widget")
  $modal.data("widget", widget)
  $modal.modal("toggle")
  
  false
)

$(document).on("click", "[data-behavior=organization-widgets] [data-behavior=select-chart]", (e) ->
  $this = $(this)
  $modal = null
  
  # Modal or inline
  $modal = $this.closest("[data-behavior=modal]")
  if $modal.length == 1
    widget = $modal.data("widget")
  else
    widget = $this.closest("[data-behavior=widget]").data("widget")
    
  widget.select_chart(JSON.parse($this.attr("data-chart")))
  $modal.modal("toggle") if $modal && $modal.length == 1
  
  false
)

# Save widgets
$(document).on("submit", "[data-behavior=organization-edit]", (e) ->
  $container = $("[data-behavior=organization-widgets]")
  $form = $(this)
  
  data = {}
  $container.find("[data-behavior=sortable]").each(->
    area = $(this).attr("data-area")
    data[area] ?= []
    
    $(this).find("[data-behavior=widget]").each(->
      $widget = $(this)
      type = $widget.attr("data-type")
      
      if type == "text"
        data[area].push(
          type: type
          values: {
            contents: $widget.find("[data-name=contents]").cleanHtml()
          }
        )
      else
        data[area].push(
          type: type
          values: $widget.find("form").serializeObject()
        )
    )
  )
  
  $form.find("[name='organization[widgets]']").val(JSON.stringify(data))
)

$(document).on("submit", "[data-behavior=organization-widgets] [data-behavior=widget] form", (e) ->
  $("[data-behavior=organization-widgets] [data-behavior=save]").trigger("click")
  
  false
)

$ ->
  $container = $("[data-behavior=organization-widgets]")
  if $container.length == 1
    # Init Widget class
    Widget.collections = JSON.parse($container.attr("data-collections"))
    
    $sortable = $container.find("[data-behavior=sortable]")
    $draggable = $container.find("[data-behavior=draggable]")
    
    # Sticky widgets
    $widgets = $("[data-behavior=widgets]")
    $widgets.sticky(topSpacing: 20)
    $widgets.css(width: $widgets.outerWidth())
    
    # Render
    $container.find("[data-behavior=render]").each(->
      new Widget(container: $(this))
    )
    
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
      cancel: ":input, button, a, [contenteditable]"
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
          type = item.attr("data-type")
          config = JSON.parse(item.attr("data-config"))
          
          # Unique item
          if config.unique
            # console.log "stop", $(this).find("[data-type=#{type}]").length
            if $(this).find("[data-type=#{type}]").length > 1
              item.remove()
              return true
          
          new Widget(container: item)
        
    )
