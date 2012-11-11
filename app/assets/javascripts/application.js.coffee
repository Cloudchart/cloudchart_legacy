# Graph
//= require graph/prototype
//= require graph/path
//= require graph/canviz
//= require graph/colors
# jQuery
//= require jquery
//= require jquery_ujs
//= require jquery/cookie
//= require jquery/base64
//= require jquery/textchange
# Other
//= require turbolinks
//= require turbolinks-analytics
//= require i18n
//= require i18n/translations

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
    store: (chart) ->
      if !chart.user_id
        charts = if $j.cookie("charts") then JSON.parse($j.cookie("charts")) else {}
        charts[chart.id] = { id: chart.id, token: chart.token }
        $j.cookie("charts", JSON.stringify(charts), { path: "/", expires: 365 })
    
    init: ->
      # Canvas
      App.canvas = new Canviz("canvas")
      
      # Create button
      $j(".create").unbind "click"
      $j(".create").bind "click", ->
        App.chart.create()
      
    demo: ($this) ->
      App.chart.show($this)
    
    create: ->
      App.loading(true)
      $j.ajax url: "/charts", dataType: "json", type: "POST", complete: (data) ->
        result = eval "(#{data.responseText})"
        App.chart.store(result.chart)
        Turbolinks.visit(result.redirect)
    
    show: ($this) ->
      App.chart.chart = JSON.parse($this.attr("data-chart"))
      $j(".canvas").css("overflow", "none")
      App.canvas.parse(App.chart.chart.xdot)
      $j(".canvas").css("overflow", "auto")
    
    edit: ($this) ->
      App.chart.status = $j(".edit_chart h3")
      clearInterval(App.chart.interval) if App.chart.interval
      App.chart.interval = setInterval( ->
        App.chart.update()
      , 30000)
      
      $j(".edit_chart").unbind "submit"
      $j(".edit_chart").bind "submit", ->
        App.chart.status.text(I18n.t("charts.autosave.saving"))
        $j(window).unbind "beforeunload"
        return true
      
      $j(".edit_chart textarea, .edit_chart input").unbind "textchange"
      $j(".edit_chart textarea, .edit_chart input").bind "textchange", ->
        App.chart.status.text(I18n.t("charts.autosave.changed"))
      
      $j(window).unbind "beforeunload"
      $j(window).bind "beforeunload", (e) ->
        e = e || window.event
        msg = I18n.t("charts.autosave.lost");
        
        if App.chart.status.text() == I18n.t("charts.autosave.changed")
          # For IE and Firefox prior to version 4
          if e
            e.returnValue = msg
          
          # For Safari
          return msg
    
    check: ->
      if $j(".edit_chart").length > 0
        App.chart.update()
    
    update: ->
      return if App.chart.status.text() != I18n.t("charts.autosave.changed")
      
      App.chart.status.text(I18n.t("charts.autosave.saving"))
      $form = $j(".edit_chart")
      $j.ajax url: $form.attr("action"), data: $form.serialize(), dataType: "json", type: $form.attr("method"), complete: (data) ->
        result = eval "(#{data.responseText})"
        if result.id
          if App.chart.status.text() != I18n.t("charts.autosave.changed")
            App.chart.status.text(I18n.t("charts.autosave.saved"))
        else
          App.chart.status.text(I18n.t("charts.autosave.error"))
      
  # User methods
  user:
    init: ->
      # Linkedin button
      $j(".sign_out").unbind "click"
      $j(".sign_out").bind "click", ->
        $j.ajax url: $j(this).attr("href"), type: "GET", complete: (data) ->
          Turbolinks.visit("/")
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
        Turbolinks.visit(location.pathname) if $j('section form').length == 0
  
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
        when "chart-edit"
          App.chart.edit($this)
      
      $j(this).attr("data-init", null)
    
$j ->
  # Turbolinks
  $j(document).live "page:fetch", ->
    App.chart.check()
    App.loading(true)
  $j(document).live "page:change", ->
    App.loading($j("[data-not-loaded]").length != 0)
    App.init()
  
  App.init()
  window.App = App