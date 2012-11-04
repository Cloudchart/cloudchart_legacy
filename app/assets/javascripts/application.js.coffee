# Graph
//= require graph/prototype
//= require graph/path
//= require graph/canviz
//= require graph/colors
# jQuery
//= require jquery
//= require jquery_ujs
# Other
//= require turbolinks

$j = jQuery.noConflict()
window.$j = $j

App = 
  loading: (flag) ->
    if flag
      $j(".progress").show()
    else
      $j(".progress").hide()
  
  # Chart methods
  chart:
    init: ->
      # Canvas
      App.canvas = new Canviz("canvas")
      
      # Create button
      $j(".create").unbind "click"
      $j(".create").bind "click", ->
        App.chart.create()
      
    demo: ->
      App.loading(true)
      $j.ajax url: "/charts/demo.xdot", type: "GET", complete: (data) ->
        App.canvas.parse(data.responseText)
        App.loading(false)
    
    create: ->
      App.loading(true)
      $j.ajax url: "/charts", dataType: "json", type: "POST", complete: (data) ->
        result = eval "(#{data.responseText})"
        Turbolinks.visit(result.redirect)
    
    show: ($this) ->
      App.loading(true)
      $j.ajax url: $this.attr("data-chart"), type: "GET", complete: (data) ->
        App.canvas.parse(data.responseText)
        App.loading(false)
      
  # User methods
  user:
    init: ->
      # Linkedin button
      $j(".sign_out").unbind "click"
      $j(".sign_out").bind "click", ->
        $j.ajax url: $j(this).attr("href"), type: "GET", complete: (data) ->
          App.user.reload()
        
        false
      
      $j(".sign_in").unbind "click"
      $j(".sign_in").bind "click", ->
        $this = $j(this)
        popup =
          width: 800
          height: 600
          left: -> (screen.width/2) - (@width/2)
          top: -> (screen.height/2) - (@height/2)
          opts: ->
            "menubar=no,toolbar=no,status=no,scrollbars=yes,width=#{@width},height=#{@height},left=#{@left()},top=#{@top()}"
          
        window.open($this.attr("data-href"), "sign_in", popup.opts())
        false
    
    reload: ->
      $j.ajax url: "/users/profile", type: "GET", complete: (data) ->
        $j(".profile").html(data.responseText)
        App.user.init()
  
  # Initialize
  init: ->
    # Search for init
    $j("[data-init]").each ->
      $this = $j(this)
      switch $j(this).attr("data-init")
        when "user"
          App.user.init($this)
        when "chart"
          App.chart.init($this)
        when "chart-demo"
          App.chart.demo($this)
        when "chart-show"
          App.chart.show($this)
      
      $j(this).attr("data-init", null)
    
$j ->
  # Turbolinks
  $j(document).live "page:fetch", ->
    App.loading(true)
  $j(document).live "page:change", ->
    App.loading($j("[data-not-loaded]").length != 0)
    App.init()
  
  App.init()
  window.App = App