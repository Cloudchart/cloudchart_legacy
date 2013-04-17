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
    @list.on("click", "[data-behavior=create-person]", ->
      self.create(identifier: $(this).attr("data-identifier"))
      false
    )
    
    # Load persons
    @persons()
  
  create: (params) ->
    self = this
    
    $.ajax(url: "/persons", data: params, dataType: "json", type: "POST")
      # .always ->
      #   
      .error (xhr, status, error) ->
        console.error error
      
      .done (result) ->
        self.persisted = result.persons
        self.render()
      
  persons: ->
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
    @loading()
    
    # Render
    @render()
    
    # Run search
    @timeout = setTimeout(=>
      self = this
      
      @loading()
      search_key = @value
      
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
  
  loading: (flag = true) ->
    @is_loading = flag
    # if @is_loading then @list.html("Loading...") else @list.empty()
  
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
      return false if !v.persisted && $.inArray(v.identifier, identifiers) > -1
      true
    )
    
    @list.html(
      HandlebarsTemplates["persons/list"](
        persons: persons
      )
    )
    
$.extend scope,
  # Person: Person,
  PersonsView: PersonsView
