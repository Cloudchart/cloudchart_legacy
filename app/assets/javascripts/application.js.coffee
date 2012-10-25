//= require_tree .
//= require jquery
//= require jquery_ujs

App = 
  # User methods
  user: 
    reload: ->
      $.ajax url: "/users/profile", type: "GET", complete: (data) ->
        $('.profile').html(data.responseText)
  
  # Initialize
  init: ->
    # Linkedin button
    $('.sign_out').live 'click', ->
      $.ajax url: $(this).attr('href'), type: "GET", complete: (data) ->
        App.user.reload()
      
      false
    
    $('.sign_in').live 'click', ->
      $this = $(this)
      popup =
        width: 640
        height: 480
        left: -> (screen.width/2) - (@width/2)
        top: -> (screen.height/2) - (@height/2)
        opts: ->
          "menubar=no,toolbar=no,status=no,width=#{@width},height=#{@height},toolbar=no,left=#{@left()},top=#{@top()}"
        
      window.open($this.attr('data-href'), "sign_in", popup.opts())
      false

$ ->
  App.init()
  window.App = App