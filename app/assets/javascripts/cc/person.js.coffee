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
    @input = @form.find("input[name='search[q]']")
    @list = @container.find("[data-behavior=list]")
    @loader = @container.find("[data-behavior=loader]")
    
    # Properties
    @is_loading = false
    @value = ""
    @results = {}
    @persisted = []
    
    # Bind events
    @form.on("submit", false)
    @input.on("textchange", =>
      @value = @input.val()
      @search()
    )
    
    # List events
    self = this
    @list.on("click", "[data-behavior=star]", ->
      $this = $(this)
      $this.toggleClass("active")
      $this.addClass("disabled")
      
      resource_params = { is_starred: $this.hasClass("active") }
      self.update({ id: $this.attr("data-identifier"), person: resource_params }, ->
        $this.removeClass("disabled")
      )
      
      false
    )
    
    # Filters events
    @container.on("click", "[data-behavior=filter]", ->
      $this = $(this)
      $this.toggleClass("active")
      
      false
    )
    
    # Load persons
    @index()
  
  # CRUD
  index: ->
    self = this
    $.ajax(url: "/persons", dataType: "json", type: "GET")
      # .always ->
      #   
      .error (xhr, status, error) ->
        console.error error
      
      .done (result) ->
        self.persisted = result.persons
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
      
      @loading()
      $.ajax(url: @form.attr("action"), data: @form.serialize(), dataType: "json", type: @form.attr("method"))
        .always ->
          self.loading(false)
        
        .error (xhr, status, error) ->
          console.error error
        
        .done (result) ->
          self.results[search_key] = result.persons
          if search_key == self.value
            self.render(search_key)
    , 1000)
  
  create: (params, callback) ->
    self = this
    
    $.ajax(url: "/persons", data: params, dataType: "json", type: "POST")
      .always ->
        callback()
        
      .error (xhr, status, error) ->
        console.error error
      
      .done (result) ->
        self.persisted = result.persons
        # self.render()
  
  update: (params, callback) ->
    self = this
    
    $.ajax(url: "/persons/#{params.id}", data: params, dataType: "json", type: "PUT")
      .always ->
        callback()
        
      .error (xhr, status, error) ->
        console.error error
      
      .done (result) ->
        # self.persisted = result.persons
        # self.render()
  
  # View
  loading: (flag = true) ->
    @is_loading = flag
    if @is_loading
      @loader.css(opacity: 1)
      @loader.find(".bar").css(width: "10%")
      @list.addClass("loading")
    else
      @loader.find(".bar").css(width: "100%")
      
      setTimeout(=>
        @loader.css(opacity: 0)
        @loader.find(".bar").css(width: "0%")
        @list.removeClass("loading")
      , 500)
  
  render: (search_key = null) ->
    search_key ?= @value
    search_exp = new RegExp(RegExp.escape(search_key), "ig")
    
    # Search through persisted persons
    persons = $.grep(@persisted, (v) ->
      return true if search_key == ""
      v.name.match(search_exp)
    )
    
    # Merge with search results
    results = @results[search_key]
    persons = persons.concat(results) if results && results[0]
    
    # Remove duplicates
    identifiers = $.map(@persisted, (v) -> v.identifier )
    persons = $.grep(persons, (v) ->
      return false if !v.is_persisted && $.inArray(v.identifier, identifiers) > -1
      true
    )
    
    @list.find("ul").remove()
    @list.append(
      HandlebarsTemplates["persons/list"](
        persons: persons
      )
    )
    
    # Bind drag
    @list.find("[data-behavior=draggable]").draggable(
      helper: "clone"
      appendTo: "body"
    )
    
$.extend scope,
  # Person: Person,
  PersonsView: PersonsView
