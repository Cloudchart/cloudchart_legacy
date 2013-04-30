root        = @
@cc        ?= {}
scope       = @cc

# class Person extends cc.Model
#   constructor: (attributes = {}) ->
#     super attributes

class PersonsView
  constructor: (attributes = {}) ->
    # Elements
    @container = attributes.container
    @form = @container.find("[data-behavior=form]")
    @input = @form.find("input[name='search[query]']")
    @list = @container.find("[data-behavior=list]")
    @loader = @container.find("[data-behavior=loader]")
    
    # Properties
    @path = @container.attr("data-path")
    @is_loading = false
    @progress = 0
    @value = ""
    @providers = @container.attr("data-providers").split(",")
    
    # Person collections
    @results = {}
    @loaded = []
    @rendered = []
    
    # Bind events
    @form.on("submit", false)
    @input.on("textchange", =>
      @value = @input.val()
      @rendered = [] if @value == ""
      @search()
    )
    
    # List events
    self = this
    @list.on("click", "[data-behavior=star]", ->
      $this = $(this)
      $this.toggleClass("active")
      $this.addClass("disabled")
      
      resource_params = { is_starred: $this.hasClass("active") }
      identifier = $this.closest("[data-identifier]").attr("data-identifier")
      
      self.update({ id: identifier, person: resource_params }, ->
        $this.removeClass("disabled")
      )
      
      false
    )
    
    # Filters events
    @container.on("click", "[data-behavior=filter]", ->
      $this = $(this)
      $this.toggleClass("active")
      
      self.input.val("")
      self.input.trigger("textchange")
      
      self.index()
      false
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
    # Check for results
    clearTimeout(@timeout) if @timeout
    
    # Render
    @render()
    
    # Run search
    @timeout = setTimeout(=>
      self = this
      
      search_key = @value
      return if search_key == ""
      
      # Start loading
      @loading(10)
      
      # Async requests for each provider
      @providers.forEach (provider) =>
        @form.find("input[name='search[provider]']").val(provider)
        data = @form.serialize()
        @form.find("input[name='search[provider]']").val("Local")
        
        $.ajax(
          url: @form.attr("action"),
          data: data,
          dataType: "json",
          type: @form.attr("method")
        ).always(->
          progress = Math.round(90/self.providers.length)
          self.loading(self.progress+progress)
        ).error((xhr, status, error) ->
          console.error error
        ).done((result) ->
          self.store(result.persons, search_key)
          if search_key == self.value
            self.render(search_key)
        )
    , 1000)
  
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
    
    # Store all rendered persons
    @rendered = @rendered.concat(persons)
    
    # Appear collapsed items with animation
    setTimeout(=>
      @list.find(".collapsed").addClass("appear")
    , 200)
    
    # Bind drag
    @list.find("[data-behavior=draggable]").draggable(
      helper: "clone"
      appendTo: "body"
    )
    
$.extend scope,
  # Person: Person,
  PersonsView: PersonsView
