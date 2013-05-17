root        = @
@persons   ?= {}
scope       = @persons

class PersonsView
  constructor: (attributes = {}) ->
    # Elements
    @container = attributes.container
    @form = @container.find("[data-behavior=form]")
    @input = @form.find("input[name='search[query]']")
    @list = @container.find("[data-behavior=list]")
    @loader = @container.find("[data-behavior=loader]")
    @modal = null
    
    # Properties
    @path = @container.attr("data-path")
    @is_loading = false
    @is_rendering = false
    @progress = 0
    @value = ""
    @providers = @container.attr("data-providers").split(",")
    
    # Person collections
    @results = {}
    @loaded = []
    @rendered = []
    
    # Textchange event
    @input.on("textchange", =>
      @value = @input.val()
      @rendered = [] if @value == ""
      @search()
    )
    
    # Load persons
    @index()
  
  # CRUD
  index: ->
    self = this
    params = {
      filters: $.map(@container.find("[data-behavior=filter].active"), (filter) -> $(filter).attr("data-filter"))
    }
    
    $.ajax(url: @path, data: params, dataType: "json", type: "GET")
      # .always ->
      #   
      .error (xhr, status, error) ->
        console.error error
      
      .done (result) ->
        # Reload loaded persons
        self.loaded = result.persons
        self.render()
  
  search: ->
    # Render
    @render()
    
    # Check for results
    clearTimeout(@timeout) if @timeout
    return if @progress > 0
    
    # Run search
    @timeout = setTimeout(=>
      self = this
      
      search_key = @value
      return if search_key == ""
      
      # Render from cache
      if @results[search_key] && @results[search_key].length > 0
        @render()
        return
      
      # Start loading
      @loading(10)
      
      # Async requests for each provider
      @providers.forEach (provider) =>
        @form.find("input[name='search[provider]']").val(provider)
        data = @form.serialize()
        @form.find("input[name='search[provider]']").val("Local")
        
        $.ajax({
          url: @form.attr("action"),
          data: data,
          dataType: "json",
          type: @form.attr("method")
        }).error((xhr, status, error) ->
          console.error error
          
          # Loading
          progress = Math.round(90/self.providers.length)
          self.loading(self.progress+progress)
        ).done((result) ->
          self.store(result.persons, search_key)
          if search_key == self.value
            self.render(search_key)
          
          # Loading
          progress = Math.round(90/self.providers.length)
          self.loading(self.progress+progress)
        )
    , 400)
  
  update: (params, callback) ->
    self = this
    
    $.ajax(url: "#{@path}/#{params.id}", data: params, dataType: "json", type: "PUT")
      .always ->
        callback()
        
      .error (xhr, status, error) ->
        console.error error
      
      .done (result) ->
        # Don't reload when searching
        if self.value == ""
          self.store([result.person])
          self.render()
  
  destroy: (params, callback) ->
    self = this
    
    $.ajax(url: "#{@path}/#{params.id}", data: params, dataType: "json", type: "DELETE")
      .always ->
        callback()
        
      .error (xhr, status, error) ->
        console.error error
      
      .done (result) ->
        # Don't reload when searching
        if self.value == ""
          self.index()
  
  # View
  loading: (progress = 0) ->
    @is_loading = progress < 100
    @progress = if @is_loading then progress else 0
    
    if @is_loading
      @loader.css(opacity: 1)
      @loader.find(".bar").css(width: "#{progress}%")
      @list.addClass("loading")
    else
      @loader.find(".bar").css(width: "100%")
      
      setTimeout(=>
        @loader.css(opacity: 0)
        @loader.find(".bar").css(width: "0%")
        @list.removeClass("loading")
      , 400)
  
  store: (persons, search_key = null) ->
    storage  = if search_key then @results[search_key] else @loaded
    storage ?= []
    
    # Unique results
    identifiers = $.map(storage, (v) -> v.identifier)
    persons.forEach((v) ->
      # Update
      if $.inArray(v.identifier, identifiers) > -1
        storage = storage.map((s) ->
          if s.identifier == v.identifier then v else s
        )
      # Append
      else
        storage.push(v)
    )
    
    if search_key
      @results[search_key] = storage
    else
      @loaded = storage
  
  render: (search_key = null) ->
    @is_rendering = true
    
    search_key ?= @value
    search_exp = new RegExp(RegExp.escape(search_key), "ig")
    
    # Search through loaded persons
    identifiers = $.map(@loaded, (v) -> v.identifier)
    persons = $.grep(@loaded, (v) ->
      return true if search_key == ""
      v.name.match(search_exp)
    )
    
    # Merge with search results
    results = @results[search_key] || []
    results.forEach((v) ->
      if $.inArray(v.identifier, identifiers) == -1
        persons.push(v)
    )
    
    # Mark unrendered as collapsed when search is in progress
    identifiers = $.map(@rendered, (v) -> v.identifier)
    if @progress >= 10
      persons.forEach((v) ->
        v.is_collapsed = $.inArray(v.identifier, identifiers) == -1
      )
    
    # Store all rendered persons
    @rendered = @rendered.concat(persons)
    
    # Sort persons by name
    persons = persons.sort((a, b) ->
      a.name.toLowerCase().localeCompare(b.name.toLowerCase())
    )
    
    @list.find("ul").remove()
    @list.append(
      HandlebarsTemplates["persons/list"](
        persons: persons
      )
    )
    
    # Appear collapsed items with animation
    if @progress >= 10 && @list.find(".collapsed").length > 0
      setTimeout(=>
        collapsed = @list.find(".collapsed")
        collapsed.addClass("appear")
        
        setTimeout(=>
          collapsed.removeClass("collapsed")
          @is_rendering = false
        , 200)
      , 200)
    else
      @is_rendering = false
    
    # Bind drag
    @list.find("[data-behavior=draggable]").draggable(
      helper: "clone"
      appendTo: "body"
    )

# Add to scope
$.extend scope,
  PersonsView: PersonsView

# Bind events
$(document).on("submit", "[data-behavior=persons-view] [data-behavior=form]", ->
  false
)

# List events
$(document).on("click", "[data-behavior=persons-view] [data-behavior=star]", ->
  @self = $(this).closest("[data-behavior=persons-view]").data("personsView")
  
  $this = $(this)
  $this.toggleClass("active")
  $this.addClass("disabled")
  
  resource_params = { is_starred: $this.hasClass("active") }
  identifier = $this.closest("[data-identifier]").attr("data-identifier")
  
  # Update when starred
  if resource_params.is_starred
    @self.update({ id: identifier, person: resource_params }, ->
      $this.removeClass("disabled")
    )
  
  # Destroy when unstarred
  else
    @self.destroy({ id: identifier, person: resource_params }, ->
      $this.removeClass("disabled")
    )
  
  false
)

# Filters events
$(document).on("click", "[data-behavior=persons-view] [data-behavior=filter]", ->
  @self = $(this).closest("[data-behavior=persons-view]").data("personsView")
  
  $this = $(this)
  $this.toggleClass("active")
  
  @self.input.val("")
  @self.input.trigger("textchange")
  
  @self.index()
  false
)

# Person events
$(document).on("click", "[data-behavior=person-manage], [data-behavior=person-new]", ->
  self = $("[data-behavior=persons-view]").data("personsView")
  
  $.ajax(url: $(this).attr("data-url"), type: "GET")
    .error (xhr, status, error) ->
      console.error error
    
    .done (result) ->
      self.modal = $("<div class='modal hide fade'>#{result}</div>")
      self.modal.modal()
  
  false
)

$(document).on("click", "[data-behavior=person-destroy]", ->
  self = $("[data-behavior=persons-view]").data("personsView")
  
  self.modal.modal("hide")
  self.modal.on("hidden", -> self.modal.remove())
  
  $this = $(this)
  $manage = $("[data-behavior=person-manage][data-identifier='#{$this.attr("data-identifier")}']")
  
  $.ajax(url: $this.attr("data-url"), dataType: "json", type: "DELETE")
    .error (xhr, status, error) ->
      console.error error
    
    .done (result) ->
      $manage.remove()
      self.index()
  
  false
)

$(document).on("click", "[data-behavior=person-edit] [data-behavior=fieldset] [data-behavior=new]", ->
  $template = $(this).closest("[data-behavior=fieldset]").find("[data-behavior=template]").clone()
  $sets = $(this).closest("[data-behavior=fieldset]").find("[data-behavior=sets]")
  
  index = Math.max($.map($(this).closest("[data-behavior=fieldset]").find("[data-behavior=index]"), (v) ->
    value = $(v).html()
    if value != "" then parseInt(value) else 0
  )...) + 1
  
  $template.removeClass("hidden")
  $template.attr("data-behavior", "")
  $template.find("[data-behavior=index]").text(index)
  $template.find("input").each(->
    $this = $(this)
    $this.attr("name", $this.attr("name").replace("%i", index))
  )
  
  $template.appendTo($sets)
  false
)

$ ->
  # Init PersonsView
  $container = $("[data-behavior=persons-view]")
  if $container.length == 1
    $container.data("personsView", new persons.PersonsView(container: $container))
    
    # Drop
    $("[data-behavior=droppable]").droppable(
      hoverClass: "active"
      drop: (event, ui) ->
        $this = ui.draggable
        identifier = $this.attr("data-identifier")
        picture = $this.attr("data-picture")
        
        node = $('<div class="img"></div>').appendTo($("#persons"))
        node.css(backgroundImage: "url(#{picture})") if picture
        
        node.attr("data-behavior", "person-manage")
        node.attr("data-identifier", identifier)
        node.attr("data-url", "#{$container.data("personsView").path}/#{identifier}/manage")
        
        # Mark person as used
        $container.data("personsView").update(id: identifier, person: { is_used: true }, ->
          $container.data("personsView").index()
        )
    )
