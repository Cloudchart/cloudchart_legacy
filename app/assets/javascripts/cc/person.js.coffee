root        = @
@cc        ?= {}
scope       = @cc

# class Person extends cc.Model
#   constructor: (attributes = {}) ->
#     super attributes

class PersonsView
  constructor: (attributes = {}) ->
    self = this
    
    # Elements
    @container = attributes.container
    @form = @container.find("[data-behavior=form]")
    @input = @form.find("input[name=q]")
    @list = @container.find("[data-behavior=list]")
    
    # Properties
    @is_loading = false
    @value = ""
    @results = {}
    
    # Bind events
    @form.on("submit", false)
    @input.on("textchange", ->
      self.value = $(this).val()
      self.search()
    )
  
  search: ->
    self = this
    
    # Check for results
    clearTimeout(@timeout) if @timeout
    self.loading()
    
    search_key = @value
    if @results[search_key] && @results[search_key][0]
      @render(search_key)
    
    # Run search
    @timeout = setTimeout(->
      self.loading()
      search_key = self.value
      
      $.ajax(url: self.form.attr("action"), data: self.form.serialize(), dataType: "json", type: self.form.attr("method"))
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
    if @is_loading then @list.html("Loading...") else @list.empty()
  
  render: (search_key = null) ->
    results = @results[search_key || @value]
    return if !results || !results[0]
    
    @list.html(
      HandlebarsTemplates["persons/list"](
        persons: results
      )
    )
    
$.extend scope,
  # Person: Person,
  PersonsView: PersonsView
