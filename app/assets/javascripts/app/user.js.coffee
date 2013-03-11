$      = jQuery
root   = @

scope  = 
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
    
    # Edit
    if $j("body").hasClass("users")
      $j(".clear").unbind "click"
      $j(".clear").bind "click", ->
        $j(this).prev().val("")
        $j(this).prev().focus()
        false
  
  reload: ->
    document.location.href = "/" if document.location.href.match(/beta/)
    Turbolinks.visit(document.location.href)
    
$.extend root,
  user: scope