$      = jQuery
root   = @

scope  = 
  current: null
  exp: new RegExp('(?:^|\\b|\\s)\@([\\w.]*)$')
  cache: {}
  note: ""
  editable: null
  
  bindings: ->
    $(".edit_chart textarea").unbind "keyup"
    $(".edit_chart textarea").bind "keyup", (e) ->
      $this = $(this)
      val = $this.val().substring(0, $this.caret())
      next = $this.val().substr($this.caret(), 1)
      matches = val.match(root.autocomplete.exp)
      
      if matches && (e.keyCode == 16 || e.keyCode == 50 || !e.keyCode) && next.strip() == ""
        root.autocomplete.show()
  
  render: ($overlay, data) ->
    $list = $overlay.find(".list")
    root.autocomplete.holder($overlay)
    identifier = if root.autocomplete.current then root.autocomplete.current.identifier else null
    
    _.map(data, (x) ->
      if x.position
        html = $("<li><div><img src='#{x.picture}'><h3>#{x.name}</h3><h4>#{x.position}</h4><p class='company'>#{x.company}</p></div><button>Profile Details</button></li>")
      else
        html = $("<li><div><img src='#{x.picture}'><h3>#{x.name}</h3><h4>#{x.headline}</h4></div><button>Profile Details</button></li>")
      
      html.data("person", x)
      html.addClass("selected") if x.identifier == identifier
      $list.append(html)
    )
    
    setTimeout(->
      $list.scrollTo(".selected", 100)
    , 100)
    
    $list.find("li div").bind "click", ->
      $this = $(this).parent()
      # return true if $this.hasClass("holder")
      
      if $this.hasClass("selected")
        $overlay.find(".for-profile .fire").trigger "click"
      else
        root.autocomplete.select_current($overlay, $this)
    
    $list.find("li button").bind "click", ->
      $this = $(this).parent()
      person = $this.data("person")
      $overlay.find(".loading").show()
      
      $.ajax url: "/charts/#{App.chart.chart.slug}/persons/#{encodeURIComponent("@#{person.identifier}")}/profile", type: "GET", complete: (data) ->
        $overlay.find("[name='person[q]']").val("@#{person.name}")
        $overlay.find(".profile").html(data.responseText).show()
        $overlay.find(".buttons").hide()
        $overlay.find(".buttons.for-profile").show()
        $overlay.find(".list").hide()
        $overlay.find(".loading").hide()
        $overlay.find(".profile textarea").val(root.autocomplete.note) if root.autocomplete.note != ""
      
      false
  
  holder: ($overlay) ->
    $input = $overlay.find("[name='person[q]']")
    $list = $overlay.find(".list")
    val = $input.val().replace(/^@/, "").trim()
    
    if val != ""
      $list.html('<li class="holder"><div><img src="/images/ico-person.png"><h3></h3><h4>Title goes here</h4><p class="company">Your Company</p></div></li>')
      $overlay.find(".holder h3").html("#{val}")
      $overlay.find(".holder").data("person",
        identifier: val,
        picture: "/images/ico-person.png"
      )
      $overlay.find(".holder").show()
      $overlay.find(".holder").closest(".controls").addClass("has-holder")
    else
      $list.empty()
      $overlay.find(".holder").closest(".controls").removeClass("has-holder")
    
    # Select holder
    identifier = if root.autocomplete.current then root.autocomplete.current.identifier else null
    if identifier == val
      $overlay.find(".holder").addClass("selected")
    
  select_current: ($overlay, $current) ->
    $overlay = $(".overlay.persons") unless $overlay
    $list = $overlay.find(".list")
    $current = $overlay.find(".list li:first") unless $current
    $input = $overlay.find("[name='person[q]']")
    
    if $current.length != 1
      root.autocomplete.current = null
      $overlay.find(".person").attr("src", $overlay.find(".person").attr("data-icon"))
    else
      data = $current.data("person")
      return unless data
      
      root.autocomplete.current = data
      $overlay.find(".person").attr("src", data.picture)
      
      # Change selection
      $list.find(".selected").removeClass("selected")
      $current.addClass("selected")
      
      setTimeout(->
        $list.scrollTo(".selected", 100)
      , 100)
      
      # # Re-render
      # if root.autocomplete.cache[$input.val()]
      #   root.autocomplete.render($overlay, root.autocomplete.cache[$input.val()])
  
  show: ($overlay = $(".overlay.persons"), editable = null)->
    $this = $(".edit_chart textarea")
    $input = $overlay.find("[name='person[q]']")
    $note = $overlay.find(".profile textarea")
    root.autocomplete.note = $overlay.find(".profile textarea").val()?.trim()
    root.autocomplete.editable = editable?.trim()
    
    root.autocomplete.current = null
    $overlay.find("form").unbind "submit"
    $overlay.find(".fire").unbind "click"
    $overlay.find(".return").unbind "click"
    $overlay.find(".holder").closest(".controls").removeClass("has-holder")
    
    $note.unbind "keydown"
    $note.bind "keydown", (e) ->
      return Mousetrap.trigger("esc") && false if e.keyCode == 27
    
    $input.val("@#{$input.attr("data-value")}")
    $input.attr("data-value", "")
    $input.unbind "textchange"
    $input.bind "textchange", ->
      # Hide profile
      if $overlay.find(".profile").is(":visible")
        $overlay.find(".profile").empty().hide()
        $overlay.find(".buttons").hide()
        $overlay.find(".buttons.for-list").show()
        $overlay.find(".list").show()
      
      # Clear current
      $overlay.find(".list").empty()
      root.autocomplete.select_current($overlay)
    
    $input.unbind "keydown"
    $input.bind "keydown", (e) ->
      # Comma
      if e.keyCode == 188 && $overlay.find(".profile").is(":visible")
        $overlay.find(".profile textarea").focus()
        return false
      
      return Mousetrap.trigger("enter") && false if e.keyCode == 13
      return Mousetrap.trigger("up") && false if e.keyCode == 38
      return Mousetrap.trigger("down") && false if e.keyCode == 40
      return Mousetrap.trigger("esc") && false if e.keyCode == 27
    
    $input.unbind "keyup"
    $input.bind "keyup", (e) ->
      return false if e.keyCode == 13 || e.keyCode == 38 || e.keyCode == 40 || e.keyCode == 27
      return true if $overlay.find(".profile").is(":visible")
      autocomplete = root.autocomplete
      
      # Placeholder
      autocomplete.render($overlay, [])
      
      # Close
      if $input.val() == ""
        # Clear current
        $overlay.find(".list").empty()
        autocomplete.select_current($overlay)
        
        $overlay.find(".for-profile .fire").trigger "click"
      
      # Search
      autocomplete.cache = {} unless autocomplete.cache
      clearTimeout(autocomplete.timeout) if autocomplete.timeout
      if autocomplete.cache[$input.val()] && autocomplete.cache[$input.val()][0]
        $overlay.find(".loading").hide()
        autocomplete.render($overlay, autocomplete.cache[$input.val()])
        return true
      
      # return false if autocomplete.loading
      autocomplete.timeout = setTimeout(->
        autocomplete.loading = true
        $overlay.find(".loading").show()
        
        cache_key = $input.val()
        $.ajax(url: $overlay.find("form").attr("action"), data: { q: cache_key.replace("@", "") }, dataType: "json", type: "GET")
          .always ->
            autocomplete.loading = false
          
          .error (xhr, status, error) ->
            $overlay.find(".loading").hide()
            console.error error
          
          .done (result) ->
            autocomplete.cache[cache_key] = result.persons
            if cache_key == $input.val()
              autocomplete.render($overlay, result.persons)
              $overlay.find(".loading").hide()
            
            if $input.val().length > 3
              # Select current
              autocomplete.select_current($overlay)
      , if e.keyCode then 1000 else 0)
      false
    
    # Fade in
    (->
      $overlay.show()
      # Focus note when editing
      if $overlay.find(".profile").is(":visible") && root.autocomplete.editable
        $note.focus()
      # Focus search when adding
      else
        $input.focus()
      
      # Don't trigger keyup when editing placeholder
      if !$overlay.find(".profile").is(":visible") && root.autocomplete.editable
        root.autocomplete.render($overlay, [])
      else
        $input.trigger "keyup"
      
      # Select current if person is opened
      if $overlay.find(".profile").is(":visible")
        $current = $overlay.find("[data-person]")
        $current.data("person", JSON.parse($current.attr("data-person")))
        root.autocomplete.select_current($overlay, $current)
      
      Mousetrap.unbind "enter"
      Mousetrap.unbind "esc"
      Mousetrap.unbind "up"
      Mousetrap.unbind "down"
      
      Mousetrap.bind "enter", ->
        if $overlay.find(".for-list").is(":visible")
          $overlay.find(".for-list .fire").trigger "click"
        else
          $overlay.find(".for-profile .fire").trigger "click"
      
      Mousetrap.bind "esc", ->
        $input.focus()
        
        if $overlay.find(".profile").is(":visible")
          # Clear current
          $input.val("")
          $overlay.find(".list").empty()
          root.autocomplete.select_current($overlay)
          
          $overlay.find(".profile").empty().hide()
          $overlay.find(".buttons").hide()
          $overlay.find(".buttons.for-list").show()
          $overlay.find(".list").show()
          $input.val("@")
          $input.trigger "keyup"
        
        else if $input.val() != "@"
          $input.val("@")
          $input.trigger "keyup"
        else
          # Clear current
          $input.val("")
          $overlay.find(".list").empty()
          root.autocomplete.select_current($overlay)
          
          $overlay.find(".for-profile .fire").trigger "click"
      
      Mousetrap.bind "up", ->
        $list = $overlay.find(".list")
        return true if $list.is(":hidden")
        
        $selected = $list.find(".selected")
        if $selected.prev().length == 1
          root.autocomplete.select_current($overlay, $selected.prev())
        else
          root.autocomplete.select_current($overlay, $overlay.find(".list li:last"))
      
      Mousetrap.bind "down", ->
        $list = $overlay.find(".list")
        return true if $list.is(":hidden")
        
        $selected = $list.find(".selected")
        if $selected.next().length == 1
          root.autocomplete.select_current($overlay, $selected.next())
        else
          root.autocomplete.select_current($overlay, $overlay.find(".list li:first"))
      
      $overlay.find("form").bind "submit", ->
        Mousetrap.trigger "enter"
        false
        
      $overlay.find(".return").bind "click", ->
        Mousetrap.trigger "esc"
        root.autocomplete.current = null
        $overlay.find(".list").empty()
        $overlay.find(".for-profile .fire").trigger "click"
        false
      
      $overlay.find(".for-list .fire").bind "click", ->
        # Trigger first row select if any
        if !root.autocomplete.current && $overlay.find(".list li").length > 0
          # Select current
          root.autocomplete.select_current($overlay)
          return false
          
        # Trigger selected row
        $selected = $overlay.find(".list li.selected")
        if $selected.length > 0
          # Select
          $selected.find("div").trigger "click"
          return false
        
        # # Trigger placeholder if visible
        # $holder = $overlay.find(".holder")
        # if $holder.is(":visible") && !$holder.hasClass("selected") && $overlay.find(".list li").length == 1
        #   $overlay.find(".holder").trigger "click"
        #   return false
      
      $overlay.find(".for-profile .fire").bind "click", ->
        editable = root.autocomplete.editable
        
        # Process or skip
        if $input.val() == "" || root.autocomplete.current || $overlay.find(".list li").length == 0
          caret = $this.caret()
          
          if root.autocomplete.current
            append = root.autocomplete.current.identifier
            
            # Note
            note = $overlay.find(".profile textarea").val()?.trim()
            if note && note != ""
              append += ", #{note.replace("\n", " ")}"
            
            # Hide profile
            if $overlay.find(".profile").is(":visible")
              Mousetrap.trigger "esc"
            
            # Replace
            if editable
              val = $this.val().substr(0, caret - editable.length + 1) + append + $this.val().substr(caret)
              move_to = caret - editable.length + 1 + append.length
            
            # Append
            else
              val = $this.val().substr(0, caret) + append + $this.val().substr(caret)
              move_to = caret + append.length
            
            $this.val(val)
            
            setTimeout ->
              $this.focus()
              $this.caret(move_to)
              $this.trigger "keydown", newline: true unless editable
              
              # Save
              App.chart.status.text(I18n.t("charts.autosave.changed"))
              App.chart.update()
            , 0
          else
            val = $this.val().substr(0, caret).replace(/\@$/, "") + $this.val().substr(caret)
            $this.val(val)
            
            setTimeout ->
              $this.focus()
              
              # Move to the right place
              if editable
                $this.caret(caret)
              
              # We removed at symbol
              else
                $this.caret(caret-1)
              
              # Save
              App.chart.status.text(I18n.t("charts.autosave.changed"))
              App.chart.update()
            , 0
          
          # Clear current
          $overlay.find(".list").empty()
          root.autocomplete.select_current($overlay)
          App.chart.edit()
          
          $overlay.hide()
          $overlay.remove() if $overlay.is(":last-child")
    )()
    
    false

$.extend root,
  autocomplete: scope