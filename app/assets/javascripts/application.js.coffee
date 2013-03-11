# Graph
//= require graph/prototype
//= require graph/path
//= require graph/canviz
//= require graph/colors
# jQuery
//= require jquery
//= require jquery_ujs
//= require jquery.ui.draggable
//= require jquery.ui.position
//= require jquery/migrate
//= require jquery/prototypes
//= require jquery/cookie
//= require jquery/base64
//= require jquery/textchange
//= require jquery/caret
//= require jquery/autosize
//= require jquery/textwidth
//= require jquery/caretposition
# Other
//= require turbolinks
//= require turbolinks-analytics
//= require i18n
//= require i18n/translations
//= require twitter/bootstrap
//= require mousetrap
//= require underscore
//= require jquery/zero
//= require jquery/popover
//= require jquery/touch-punch
//= require jquery/scrollto
//= require jquery/jqplugin
//= require jquery/has-scrollbar

# App
//= require app/index

# jQuery
jQuery.migrateMute = true
$j = jQuery.noConflict()

root = @
root.$j = $j

App = 
  # Global loading
  loading: (flag) ->
    if flag
      # height = if $j("footer").length > 0 then $j("footer").offset().top else $j("html").height() - $j("header").height()
      # $j(".loading .bar").css(top: Math.min(height/2, ($j("html").height() - $j("header").height())/2) - $j(".loading .bar").height()/2)
      # $j(".loading").css(height: height).show()
      
      return false if $j("body > .loading").is(":visible")
      $j("body > .loading").show()
    else
      $j("body > .loading").hide()
    
    true
  # Initialize
  init: ->
    # IE Overlay
    if $j(".overlay.ie").length > 0
      $j(".overlay.ie input.email").unbind "textchange"
      $j(".overlay.ie input.email").bind "textchange", ->
        $this = $j(this)
        $email = $this.parent().next()
        
        if $this.val().strip() != "" && /\S+@\S+\.\S+/.test($this.val())
          $email.removeClass("disabled")
          $email.addClass("pressme")
        else
          $email.addClass("disabled")
          $email.removeClass("pressme")
      
      $j(".overlay.ie form").unbind "submit"
      $j(".overlay.ie form").bind "submit", ->
        $j(".overlay.ie button.email").trigger "click"
        false
      
      $j(".overlay.ie .clear").unbind "click"
      $j(".overlay.ie .clear").bind "click", ->
        $j(this).prev().prev().find("input").val("")
        $j(this).prev().prev().find("input").focus()
        false
      
      $j(".overlay.ie button.email").unbind "click"
      $j(".overlay.ie button.email").bind "click", ->
        $this = $j(this)
        $input = $this.prev().find("input")
        
        if $this.hasClass("pressme")
          $form = $j(".overlay.ie form")
          $j.ajax url: $form.attr("action"), data: $form.serialize(), dataType: "json", type: "POST", complete: (data) ->
            if data.status == 200
              $this.text($this.attr("data-success"))
              $input.val("")
              
              setTimeout ->
                $this.addClass("disabled")
                $this.removeClass("pressme")
                $this.text($this.attr("data-ready"))
              , 1000
            else
              $this.text($this.attr("data-error"))
          
        false
        
      $j(".overlay.ie .fire").unbind "click"
      $j(".overlay.ie .fire").bind "click", ->
        document.location.href = "http://google.com/chrome"
        false
      
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

# Extend App with scopes
$j.extend App,
  autocomplete: root.autocomplete
  chart: root.chart
  user: root.user

$j ->
  # Turbolinks
  $j(document).live "page:fetch", ->
    App.chart.check()
    App.loading(true)
  $j(document).live "page:change", ->
    App.chart.skip = false
    App.loading($j("[data-not-loaded]").length != 0)
    App.init()
  
  root.App = App
  App.init()
