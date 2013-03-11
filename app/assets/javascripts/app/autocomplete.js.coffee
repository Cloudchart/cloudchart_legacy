$      = jQuery
root   = @

scope  = 
  current: null
  exp: new RegExp('(?:^|\\b|\\s)\@([\\w.]*)$')
  cache: {}
  
  bindings: ->
    $(".edit_chart textarea").unbind "keyup"
    $(".edit_chart textarea").bind "keyup", (e) ->
      $this = $(this)
      val = $this.val().substring(0, $this.caret())
      next = $this.val().substr($this.caret(), 1)
      matches = val.match(root.autocomplete.exp)
      
      if matches && (e.keyCode == 16 || e.keyCode == 50 || !e.keyCode) && next.strip() == ""
        root.autocomplete.show()
  
  render: (data) ->
    $(".overlay.persons .list").empty()
    val = if root.autocomplete.current then root.autocomplete.current.val else null
    
    _.map(data, (x) ->
      html = $("<li><div><img src='#{x.picture_url}'><h3>#{x.name}</h3><p>#{x.headline}</p></div></li>")
      html.data("person", x)
      html.addClass("selected") if x.val == val
      $(".overlay.persons .list").append(html)
    )
    
    $(".overlay.persons .list li").bind "click", ->
      $this = $(this)
      $overlay = $(".overlay.persons")
      
      if $this.hasClass("selected")
        person = $this.data("person")
        $overlay.find(".loading").show()
        
        $.ajax url: "/charts/#{App.chart.chart.slug}/persons/#{encodeURIComponent("@#{person.val}")}/profile", type: "GET", complete: (data) ->
          $overlay.find("[name='person[q]']").val("@#{person.name}")
          $overlay.find(".profile").html(data.responseText).show()
          $overlay.find(".buttons").hide()
          $overlay.find(".buttons.for-profile").show()
          $overlay.find(".list").hide()
          $overlay.find(".loading").hide()
      else
        root.autocomplete.select_current($overlay, $(this))
  
  select_current: ($overlay, $current) ->
    $overlay = $(".overlay.persons") unless $overlay
    $current = $overlay.find(".list li:first") unless $current
    $input = $overlay.find("[name='person[q]']")
    
    if $current.length != 1 || root.autocomplete.loading
      root.autocomplete.current = null
      $overlay.find(".person").attr("src", $overlay.find(".person").attr("data-icon"))
    else
      data = $current.data("person")
      root.autocomplete.current = data
      $overlay.find(".person").attr("src", data.picture_url)
      
      # Re-render
      if root.autocomplete.cache[$input.val()]
        root.autocomplete.render(root.autocomplete.cache[$input.val()])
  
  show: ($overlay = $(".overlay.persons"))->
    $this = $(".edit_chart textarea")
    $input = $overlay.find("[name='person[q]']")
    
    root.autocomplete.current = null
    $overlay.find("form").unbind "submit"
    $overlay.find(".fire").unbind "click"
    $overlay.find(".return").unbind "click"
    $overlay.find(".holder").unbind "click"
    $overlay.find(".holder").removeClass("selected").hide()
    $overlay.find(".holder").parent().removeClass("has-holder")
    
    $input.val("@#{$input.attr('data-value')}")
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
      return false if e.keyCode == 13
      return true if $overlay.find(".profile").is(":visible")
      
      autocomplete = root.autocomplete
      val = $input.val().replace(/^@/, "").trim()
      
      # Placeholder
      $overlay.find(".holder h3").html("@#{val}")
      if val != ""
        $overlay.find(".holder").show()
        $overlay.find(".holder").parent().addClass("has-holder")
      else
        $overlay.find(".holder").hide()
        $overlay.find(".holder").parent().removeClass("has-holder")
      
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
        autocomplete.render(autocomplete.cache[$input.val()])
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
            values = _.map(result.persons, (x) ->
              name = "#{x.first_name} #{x.last_name}"
              picture_url = if x.picture_url then x.picture_url else "/images/ico-person.png"
              
              { val: "#{name}(ln:#{x.id})", name: name, headline: x.headline, picture_url: picture_url }
            )
            
            autocomplete.cache[cache_key] = values
            if cache_key == $input.val()
              autocomplete.render(values)
              $overlay.find(".loading").hide()
            
            if $input.val().length > 3
              # Select current
              autocomplete.select_current($overlay)
      , if e.keyCode then 1000 else 0)
      false
    
    # Fade in
    (->
      $overlay.show()
      $input.focus()
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
        if $overlay.find(".profile").is(":visible")
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
        
        $list.scrollTo(".selected", 100)
      
      Mousetrap.bind "down", ->
        $list = $overlay.find(".list")
        return true if $list.is(":hidden")
        
        $selected = $list.find(".selected")
        if $selected.next().length == 1
          root.autocomplete.select_current($overlay, $selected.next())
        else
          root.autocomplete.select_current($overlay, $overlay.find(".list li:first"))
        
        $list.scrollTo(".selected", 100)
      
      $overlay.find(".holder").bind "click", ->
        $(this).addClass("selected")
        root.autocomplete.current = 
          val: $input.val().replace(/^@/, "")
        $overlay.find(".for-profile .fire").trigger "click"
      
      $overlay.find("form").bind "submit", ->
        $overlay.find(".for-profile .fire").trigger "click"
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
          $selected.trigger "click"
          return false
        
        # Trigger placeholder if visible
        $holder = $overlay.find(".holder")
        if $holder.is(":visible") && !$holder.hasClass("selected") && $overlay.find(".list li").length == 0
          $overlay.find(".holder").trigger "click"
          return false
      
      $overlay.find(".for-profile .fire").bind "click", ->
        # Process or skip
        if $input.val() == "" || root.autocomplete.current || $overlay.find(".list li").length == 0
          caret = $this.caret()
          if root.autocomplete.current
            append = root.autocomplete.current.val
            
            # Note
            note = $overlay.find(".profile textarea").val()?.trim()
            if note && note != ""
              append += ", #{note.replace("\n", " ")}"
            
            # Hide profile
            if $overlay.find(".profile").is(":visible")
              Mousetrap.trigger "esc"
            
            val = $this.val().substr(0, caret) + append + $this.val().substr(caret)
            $this.val(val)
            
            setTimeout ->
              $this.focus()
              $this.caret(caret+append.length)
              $this.trigger "keydown", newline: true
              
              # Save
              App.chart.status.text(I18n.t("charts.autosave.changed"))
              App.chart.update()
            , 0
          else
            val = $this.val().substr(0, caret).replace(/\@$/, "") + $this.val().substr(caret)
            $this.val(val)
            
            setTimeout ->
              $this.focus()
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