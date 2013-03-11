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

jQuery.migrateMute = true
$j = jQuery.noConflict()
window.$j = $j

App = 
  loading: (flag) ->
    if flag
      # height = if $j("footer").length > 0 then $j("footer").offset().top else $j("html").height() - $j("header").height()
      # $j(".loading .bar").css(top: Math.min(height/2, ($j("html").height() - $j("header").height())/2) - $j(".loading .bar").height()/2)
      # $j(".loading").css(height: height).show()
      $j("body > .loading").show()
    else
      $j("body > .loading").hide()
  
  # Chart methods
  chart:
    cache:
      breaks: {}
    
    store: (chart) ->
      if !chart.user_id
        charts = if $j.cookie("charts") then JSON.parse($j.cookie("charts")) else {}
        charts[chart.id] = { id: chart.id, token: chart.token }
        $j.cookie("charts", JSON.stringify(charts), { path: "/", expires: 365 })
    
    demo: ($this) ->
      App.chart.show($this)
    
    create: (href = "/charts") ->
      App.loading(true)
      $j.ajax url: href, dataType: "json", type: "POST", complete: (data) ->
        result = eval "(#{data.responseText})"
        App.chart.store(result.chart)
        Turbolinks.visit(result.redirect_to)
    
    show: ($this) ->
      App.chart.chart = JSON.parse($this.attr("data-chart"))
      $j(".canvas").css("overflow", "none")
      App.canvas.parse(App.chart.chart.xdot)
      App.chart.resize()
      $j(".canvas").css("overflow", "auto")
    
    init: ->
      App.chart.resize(0)
      $j(window).unbind "resize"
      $j(window).bind "resize", -> App.chart.resize()
      
      # Canvas
      App.canvas = new Canviz("canvas") if $j("#canvas").length > 0
      
      # Breadcrumb
      App.chart.breadcrumb()
      
      # Create button
      $j(".create").unbind "click"
      $j(".create").bind "click", ->
        App.chart.create()
        false
      
      # Clone button
      $j(".clone").unbind "click"
      $j(".clone").bind "click", ->
        App.chart.create($j(this).attr("href"))
        false
        
      # Error icon
      $j("header figure .error").popover
        my: "center top",
        at: "center bottom",
        offset: "0 18px"
      
      # Context
      $j("header .context").popover
        my: "center top",
        at: "center bottom",
        offset: "0 -1px"
      
      $j("header .context").unbind "popover-show"
      $j("header .context").bind "popover-show", ->
        src = $j(this).find("img").attr("src")
        if src.match(/arrow/)
          $j(this).find("img").attr("src", $j(this).attr("data-selected"))
      
      $j("header .context").unbind "popover-hide-animation-complete"
      $j("header .context").bind "popover-hide-animation-complete", ->
        src = $j(this).find("img").attr("src")
        if src.match(/arrow/)
          $j(this).find("img").attr("src", $j(this).attr("data-normal"))
      
      # Context buttons and overlays
      $j("header .btn-share, header .btn-rename, header .btn-history, header .btn-delete").unbind "click"
      $j("header .btn-share, header .btn-rename, header .btn-history, header .btn-delete").bind "click", ->
        cls = $j(this).attr("class").replace("btn-", "")
        
        $j("header .context").data("popover").hide()
        $j(".overlay.#{cls}").fadeIn(->
          return unless cls == "share"
          
          # Share
          click = ->
            $this = $j(this)
            $input = $this.prev().find("input")
            $email = $this.next()
            
            if $email.hasClass("progress")
              # if $input.val().strip() != ""
              #   $email.removeClass("pressme")
              #   $email.addClass("disabled")
              #   $email.text($email.attr("data-send"))
              #   $input.val("")
              #   return false
              
              $email.removeClass("disabled")
              $email.removeClass("pressme")
              $email.removeClass("progress")
              $this.text($this.attr("data-text"))
              $email.text($email.attr("data-text"))
              $input.val($input.attr("data-value"))
              $input.attr("placeholder", "")
              return false
          
          $j(".overlay.share button.copy").unbind "click"
          $j(".overlay.share button.copy").bind "click", (e) ->
            e.preventDefault()
            return false if $j.browser.flash
            
            if $j(this).next().hasClass("progress")
              click.apply(this)
            else
              window.open $j(this).parent().find(":first").find("input").val()
            
            false
          
          return unless $j.browser.flash
          $j(".overlay.share button.copy").zclip
            path: "/zero.swf"
            copy: ->
              $j(this).attr("data-clipboard-text")
            afterCopy: ->
              click.apply(this)
        )
        
        false
      
      $j(".overlay .cancel").unbind "click"
      $j(".overlay .cancel").bind "click", ->
        Mousetrap.unbind "esc"
        $j(this).closest(".overlay").fadeOut ->
          $j(this).hide()
      
      $j(".overlay.person .cancel").bind "click", ->
        $text = $j(".edit_chart textarea")
        $note = $j(".overlay.person .profile textarea")
        note = $note.val()?.trim()
        
        # Note
        if note && note != "" && $text.length > 0
          title = $note.attr("data-title")
          prev = $note.attr("data-prev")
          
          val = $text.val().replace(title, "#{title.split(",")[0]}, #{note.replace("\n", " ")}")
          $text.val(val)
          App.chart.status.text(I18n.t("charts.autosave.changed"))
          App.chart.update()
        
      
      $j(".overlay.share button.email").unbind "click"
      $j(".overlay.share button.email").bind "click", ->
        $this = $j(this)
        $input = $this.prev().prev().find("input")
        $copy = $this.prev()
        
        if $this.hasClass("pressme")
          $form = $j(".overlay.share form")
          $form.find("[name='share[type]']").val($this.attr("data-type"))
          
          $j.ajax url: $form.attr("action"), data: $form.serialize(), dataType: "json", type: "POST", complete: (data) ->
            if data.status == 200
              $this.removeClass("disabled")
              $this.removeClass("pressme")
              $this.removeClass("progress")
              $copy.text($copy.attr("data-text"))
              $this.text($this.attr("data-sent"))
              $input.val($input.attr("data-value"))
              $input.attr("placeholder", "")
              setTimeout ->
                $this.text($this.attr("data-text"))
              , 1000
            else
              $this.text($this.attr("data-error"))
          
          return false
        
        return false if $this.hasClass("disabled")
        
        $this.toggleClass("progress")
        if $this.hasClass("progress")
          $this.attr("data-text", $this.text()) unless $this.attr("data-text")
          
          $this.text($this.attr("data-send"))
          $this.addClass("disabled")
          
          $input.val("")
          $input.attr("placeholder", I18n.t("charts.share.placeholder"))
          $input.focus()
          
          $copy.attr("data-text", $copy.text())
          $copy.text($copy.attr("data-replace"))
          
        false
        
      $j(".overlay.share input.email").unbind "textchange"
      $j(".overlay.share input.email").bind "textchange", ->
        $this = $j(this)
        $email = $this.parent().next().next()
        
        return false unless $email.hasClass("progress")
        
        if $this.val().strip() != "" && /\S+@\S+\.\S+/.test($this.val())
          $email.removeClass("disabled")
          $email.addClass("pressme")
          $email.text($email.attr("data-send"))
        else
          $email.addClass("disabled")
          $email.removeClass("pressme")
          $email.text($email.attr("data-send"))
        
      # Rename
      $j("header .btn-rename").bind "click", ->
        $form = $j(".edit_chart")
        title = prompt(I18n.t("charts.rename.descr"), $form.find("[name='chart[title]']").val())
        title = title.strip() if title
        
        if title && title != ""
          App.chart.status.text(I18n.t("charts.autosave.changed"))
          $form.find("[name='chart[title]']").val(title)
          $j("header .chart-title").text(title)
          
          App.chart.update(false)
        
        false
        
      # Delete
      $j(".overlay.delete .fire").unbind "click"
      $j(".overlay.delete .fire").bind "click", ->
        $j(".overlay.delete .cancel").trigger "click"
        App.loading(true)
        
        $j.ajax url: $j(this).attr("data-action"), dataType: "json", type: "DELETE", complete: (data) ->
          result = eval "(#{data.responseText})"
          Turbolinks.visit(result.redirect_to)
      
      # History
      $j("header .btn-history").bind "click", ->
        App.loading(true)
        
        $j.ajax url: $j(".overlay.history").attr("data-action"), type: "GET", complete: (data) ->
          $j(".overlay.history .content").html(data.responseText)
          App.loading(false)
          
          $j(".overlay.history .restore").unbind "click"
          $j(".overlay.history .restore").bind "click", ->
            $j(".overlay.history .cancel").trigger "click"
            App.loading(true)
            
            $j.ajax url: $j(this).attr("data-action"), dataType: "json", type: "PUT", complete: (data) ->
              result = eval "(#{data.responseText})"
              Turbolinks.visit(result.redirect_to)
          
          $j(".overlay.history .clone").unbind "click"
          $j(".overlay.history .clone").bind "click", ->
            $j(".overlay.history .cancel").trigger "click"
            App.loading(true)
            
            $j.ajax url: $j(this).attr("data-action"), dataType: "json", type: "POST", complete: (data) ->
              result = eval "(#{data.responseText})"
              Turbolinks.visit(result.redirect_to)
      
      # Switch editor buttons
      $j(".show-editor").unbind "click"
      $j(".show-editor").bind "click", ->
        $j(".chart").addClass("editing")
        false
      
      $j(".hide-editor").unbind "click"
      $j(".hide-editor").bind "click", ->
        App.chart.check()
        $j(".chart").removeClass("editing")
        false
    
    sidebar: (width) ->
      if $j(".edit_chart textarea").length == 0
        $j(".left, .editor").css(width: 0)
        $j(".right, .btn-divider").css(left: 0)
        return
        
      if width?
        sidebar = Math.max(0, Math.min($j("html").width()-13, width))
        if $j("[name='chart[sidebar]']").length > 0
          App.chart.status.text(I18n.t("charts.autosave.changed"))
          $j("[name='chart[sidebar]']").val(sidebar)
      else if $j("[name='chart[sidebar]']").length > 0
        sidebar = Math.max(0, Math.min($j("html").width()-13, parseInt($j("[name='chart[sidebar]']").val())))
      else
        sidebar = 0
      
      $j(".left, .editor").css(width: sidebar)
      $j(".right, .btn-divider").css(left: sidebar)
      
      # Editor lines
      App.chart.cache.breaks = {}
      App.chart.lines()
      App.chart.update()
    
    resize: (timeout = 500) ->
      # Fill height
      $j(".chart, .chart .left").css(
        "height",
        Math.max(250 + $j(".chart .header").outerHeight(), $j("html").height() - $j("header").outerHeight() - $j(".breadcrumb").outerHeight())
      )
      
      $j(".chart .canvas, #canvas div:eq(0)").css(
        "height",
        Math.max(250, $j("html").height() - $j("header").outerHeight() - $j(".breadcrumb").outerHeight() - $j(".chart .header").outerHeight())
      )
      
      # Move canvas
      $j("#canvas").css(bottom: 65) if $j(".chart .header").length > 0
      
      # Autosize
      if $j(".edit_chart textarea").length > 0
        $j(".edit_chart textarea").autosize()
        $j(".edit_chart textarea").css("minHeight", $j(".left").height()-parseInt($j(".left .text").css("top")))
        
      # Sidebar width
      clearTimeout(App.chart.sidebarTimeout) if App.chart.sidebarTimeout
      if timeout > 0
        App.chart.sidebarTimeout = setTimeout(App.chart.sidebar, timeout)
      else
        App.chart.sidebar()
    
    lines: ->
      $this = $j(".edit_chart textarea")
      
      lines = $this.val().split("\n")
      levels = {}
      
      list = for line in lines
        num = _i + 1
        
        level = line.level()
        levels[level] = 0 unless levels[level]
        levels[level]++
        _.each(levels, (_, i) ->
          levels[i] = 0 if i > level
        )
        
        tab = if $j.browser.safari || $j.browser.opera || $j.browser.msie then "____" else "__"
        text = "#{line.replace(/\t/g, tab)}"
        
        if App.chart.cache.breaks[text]
          breaks = App.chart.cache.breaks[text]
        else
          width = $this.textWidth(text)
          breaks = App.chart.cache.breaks[text] = Math.ceil((width + 1) / $this.width())
        
        str = []
        for lvl in [0..level]
          str.push levels[lvl]
        
        "<li>#{str.join(".")}</li>" + ("<li>&nbsp;</li>".repeat(breaks-1))
      
      $j(".text ul").html(list.join("\n"))
    
    indent: (right = true) ->
      $this = $j(".edit_chart textarea")
      
      lines = $this.val().split("\n")
      line = $this.caretLine()-1
      caret = $this.caret()
      sel = [$this.getSelectionStart(), $this.getSelectionEnd()]
      
      if $this.caretSelection().trim() != ""
        indent = _.map([1..$this.caretSelection().trim().split("\n").length], (i) -> line+i-1)
      else
        indent = [line]
      
      prev_line_level = (lines[indent[0]-1] || "").level()
      first_line_level = lines[indent[0]].level()
      last_line_level = lines[indent[indent.length-1]].level()
      offset = 0
      first = true
      if (right && first_line_level < prev_line_level + 1) || (!right && last_line_level > 0)
        if indent.length == 1
          offset += if right then 1 else -1
          
        _.each(indent, (line, _i) ->
          if right
            lines[line] = "\t#{lines[line]}"
            if _i == 0 && $this.val().substr($this.caret()-1, 1) != "\n"
              sel[0] = sel[0] + 1
            
            sel[1] = sel[1] + 1
          
          # Left
          else
            match = lines[line].match(/\t/)
            if match
              sel[1] = sel[1] - 1
              lines[line] = lines[line].replace(/\t/, "")
            
            if _i == 0 && match && $this.val().substr($this.caret()-1, 1) != "\n"
              sel[0] = sel[0] - 1
        )
      
      $this.val(lines.join("\n"))
      if indent.length > 1
        # console.log sel
        $this.setCaretSelection(sel[0], sel[1])
      else
        $this.caret(caret+offset)
    
    breadcrumb: ->
      # Breadcrumb
      $j(".breadcrumb a[href^='#']").popover
        my: "center top",
        at: "center bottom",
        offset: "0 18px"
      
      # Switch breadcrumb buttons
      $j(".show-breadcrumb").unbind "click"
      $j(".show-breadcrumb").bind "click", ->
        $j(".hide-breadcrumb").show()
        $j(".breadcrumb").addClass("showing")
        false
      
      $j(".hide-breadcrumb").unbind "click"
      $j(".hide-breadcrumb").bind "click", ->
        $j(".hide-breadcrumb").hide()
        $j(".breadcrumb").removeClass("showing")
        false
    
    autocomplete:
      current: null
      exp: new RegExp('(?:^|\\b|\\s)\@([\\w.]*)$')
      
      render: (data) ->
        $j(".overlay.persons .list").empty()
        val = if App.chart.autocomplete.current then App.chart.autocomplete.current.val else null
        
        _.map(data, (x) ->
          html = $j("<li><div><img src='#{x.picture}'><h3>#{x.name}</h3><p>#{x.headline}</p></div></li>")
          html.data("person", x)
          html.addClass("selected") if x.val == val
          $j(".overlay.persons .list").append(html)
        )
        
        $j(".overlay.persons .list li").bind "click", ->
          $this = $j(this)
          $overlay = $j(".overlay.persons")
          
          if $this.hasClass("selected")
            person = $this.data("person")
            $overlay.find(".loading").show()
            
            $j.ajax url: "/charts/#{App.chart.chart.slug}/persons/#{encodeURIComponent("@#{person.val}")}/profile", type: "GET", complete: (data) ->
              $overlay.find("[name='person[q]']").val("@#{person.name}")
              $overlay.find(".profile").html(data.responseText).show()
              $overlay.find(".buttons").hide()
              $overlay.find(".buttons.for-profile").show()
              $overlay.find(".list").hide()
              $overlay.find(".loading").hide()
          else
            App.chart.autocomplete.select_current($overlay, $j(this))
      
      select_current: ($overlay, $current) ->
        $overlay = $j(".overlay.persons") unless $overlay
        $current = $overlay.find(".list li:first") unless $current
        $input = $overlay.find("[name='person[q]']")
        
        if $current.length != 1 || App.chart.autocomplete.loading
          App.chart.autocomplete.current = null
          $overlay.find(".person").attr("src", $overlay.find(".person").attr("data-icon"))
        else
          data = $current.data("person")
          App.chart.autocomplete.current = data
          $overlay.find(".person").attr("src", data.picture)
          
          # Re-render
          if App.chart.autocomplete.cache[$input.val()]
            App.chart.autocomplete.render(App.chart.autocomplete.cache[$input.val()])
      
      bindings: ->
        $j(".edit_chart textarea").unbind "keyup"
        $j(".edit_chart textarea").bind "keyup", (e) ->
          $this = $j(this)
          val = $this.val().substring(0, $this.caret())
          next = $this.val().substr($this.caret(), 1)
          matches = val.match(App.chart.autocomplete.exp)
          
          if matches && (e.keyCode == 16 || e.keyCode == 50 || !e.keyCode) && next.strip() == ""
            App.chart.autocomplete.show()
      
      show: ($overlay = $j(".overlay.persons"))->
        $this = $j(".edit_chart textarea")
        $input = $overlay.find("[name='person[q]']")
        
        App.chart.autocomplete.current = null
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
          App.chart.autocomplete.select_current($overlay)
        
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
          
          autocomplete = App.chart.autocomplete
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
            $j.ajax(url: $overlay.find("form").attr("action"), data: { q: cache_key.replace("@", "") }, dataType: "json", type: "GET")
              .always ->
                autocomplete.loading = false
              
              .error (xhr, status, error) ->
                $overlay.find(".loading").hide()
                console.error error
              
              .done (result) ->
                values = _.map(result.persons, (x) ->
                  name = "#{x.first_name} #{x.last_name}"
                  picture = if x.picture_url then x.picture_url else "/images/ico-person.png"
                  
                  { val: "#{name}(ln:#{x.id})", name: name, headline: x.headline, picture: picture }
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
              App.chart.autocomplete.select_current($overlay)
              
              $overlay.find(".for-profile .fire").trigger "click"
          
          Mousetrap.bind "up", ->
            $list = $overlay.find(".list")
            return true if $list.is(":hidden")
            
            $selected = $list.find(".selected")
            if $selected.prev().length == 1
              App.chart.autocomplete.select_current($overlay, $selected.prev())
            else
              App.chart.autocomplete.select_current($overlay, $overlay.find(".list li:last"))
            
            $list.scrollTo(".selected", 100)
          
          Mousetrap.bind "down", ->
            $list = $overlay.find(".list")
            return true if $list.is(":hidden")
            
            $selected = $list.find(".selected")
            if $selected.next().length == 1
              App.chart.autocomplete.select_current($overlay, $selected.next())
            else
              App.chart.autocomplete.select_current($overlay, $overlay.find(".list li:first"))
            
            $list.scrollTo(".selected", 100)
          
          $overlay.find(".holder").bind "click", ->
            $j(this).addClass("selected")
            App.chart.autocomplete.current = 
              val: $input.val().replace(/^@/, "")
            $overlay.find(".for-profile .fire").trigger "click"
          
          $overlay.find("form").bind "submit", ->
            $overlay.find(".for-profile .fire").trigger "click"
            false
          
          $overlay.find(".return").bind "click", ->
            Mousetrap.trigger "esc"
            App.chart.autocomplete.current = null
            $overlay.find(".list").empty()
            $overlay.find(".for-profile .fire").trigger "click"
            false
          
          $overlay.find(".for-list .fire").bind "click", ->
            # Trigger first row select if any
            if !App.chart.autocomplete.current && $overlay.find(".list li").length > 0
              # Select current
              App.chart.autocomplete.select_current($overlay)
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
            if $input.val() == "" || App.chart.autocomplete.current || $overlay.find(".list li").length == 0
              caret = $this.caret()
              if App.chart.autocomplete.current
                append = App.chart.autocomplete.current.val
                
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
              App.chart.autocomplete.select_current($overlay)
              App.chart.edit()
              
              $overlay.hide()
              $overlay.remove() if $overlay.is(":last-child")
        )()
        
        false
    
    # TODO: Speedup - ?
    edit: ($this) ->
      App.chart.status = $j(".edit_chart h3")
      clearInterval(App.chart.interval) if App.chart.interval
      App.chart.interval = setInterval( ->
        App.chart.update()
      , 10000)
      
      # Autocomplete
      App.chart.autocomplete.bindings()
      
      # Shortcuts
      Mousetrap.unbind "enter"
      Mousetrap.unbind "esc"
      Mousetrap.unbind "up"
      Mousetrap.unbind "down"
      Mousetrap.unbind "left"
      Mousetrap.unbind "right"
      
      Mousetrap.unbind ["alt+enter", "ctrl+enter"]
      Mousetrap.unbind ["alt+up", "ctrl+up"]
      Mousetrap.unbind ["alt+down", "ctrl+down"]
      Mousetrap.unbind ["alt+left", "ctrl+left"]
      Mousetrap.unbind ["alt+right", "ctrl+right"]
      
      Mousetrap.bind "enter", ->
        return true if $j(".edit_chart textarea").is(":focus") || $j(".canvas").hasScrollBar()
        Mousetrap.trigger "alt+enter"
      
      Mousetrap.bind "up", ->
        return true if $j(".edit_chart textarea").is(":focus") || $j(".canvas").hasScrollBar()
        Mousetrap.trigger "alt+up"
      
      Mousetrap.bind "down", ->
        return true if $j(".edit_chart textarea").is(":focus") || $j(".canvas").hasScrollBar()
        Mousetrap.trigger "alt+down"
      
      Mousetrap.bind "left", ->
        return true if $j(".edit_chart textarea").is(":focus") || $j(".canvas").hasScrollBar()
        Mousetrap.trigger "alt+left"
      
      Mousetrap.bind "right", ->
        return true if $j(".edit_chart textarea").is(":focus") || $j(".canvas").hasScrollBar()
        Mousetrap.trigger "alt+right"
      
      Mousetrap.bind ["alt+enter", "ctrl+enter"], ->
        $popover = $j("#children:visible")
        $active = $popover.find(".list a.active")
        return false if $active.length == 0
        
        Turbolinks.visit $active.attr("href")
        false
      
      Mousetrap.bind ["alt+up", "ctrl+up"], ->
        $popover = $j("#children:visible")
        return false if $popover.length == 0
        
        $active = $popover.find(".list a.active").prev()
        $active = $popover.find(".list a:last") if $active.length == 0
        
        $popover.find(".list a").removeClass("active")
        $active.addClass("active")
        false
      
      Mousetrap.bind ["alt+down", "ctrl+down"], ->
        $popover = $j("#children:visible")
        return false if $popover.length == 0
        
        $active = $popover.find(".list a.active").next()
        $active = $popover.find(".list a:first") if $active.length == 0
        
        $popover.find(".list a").removeClass("active")
        $active.addClass("active")
        false
      
      Mousetrap.bind ["alt+left", "ctrl+left"], ->
        $active = $j(".breadcrumb li.active")
        if $active.length == 1
          Turbolinks.visit $active.prev().find("a").attr("href")
        false
        
      Mousetrap.bind ["alt+right", "ctrl+right"], ->
        $active = $j(".breadcrumb li.active")
        if $active.length == 1
          $popover = $active.next().find("a")
          if $popover.length == 1
            if $popover.attr("href") == "#children"
              $popover.trigger "click"
              $j($popover.attr("href")).find(".list a:first").addClass("active")
            else
              Turbolinks.visit $popover.attr("href")
          
        false
      
      # Buttons
      $j(".buttons .add-person").unbind "click"
      $j(".buttons .add-person").bind "click", ->
        $area = $j(".edit_chart textarea")
        text = $area.val()
        caret = $area.caret()
        
        if caret >= 0
          prev = text.substr(caret-1, 1)
          insert = "@"
          
          if caret != 0 && !_.include(["\n", "\t", " "], prev)
            insert = " @"
          
          text = text.insert(caret, insert)
          $area.val(text)
          $area.caret(caret+insert.length)
          $area.trigger "keyup"
        
        false
      
      $j(".buttons .left-indent").unbind "click"
      $j(".buttons .left-indent").bind "click", ->
        App.chart.indent(false)
        App.chart.lines()
        false
      
      $j(".buttons .right-indent").unbind "click"
      $j(".buttons .right-indent").bind "click", ->
        App.chart.indent(true)
        App.chart.lines()
        false
      
      $j(".buttons .move").unbind "click"
      $j(".buttons .move").bind "click", ->
        $j(this).toggleClass("selected")
        $area = $j(".edit_chart textarea")
        $area.caret($area.caret())
        false
      
      # Key event
      # $j(".edit_chart textarea").focus()
      $j(".edit_chart textarea").unbind "keydown"
      $j(".edit_chart textarea").bind "keydown", (e, data) ->
        $this = $j(this)
        
        # Check for person
        line = $this.caretLine() - 1
        lines = $this.val().split("\n")
        current_line = lines[line]
        previous_line = lines[line-1]
        current_char = $this.val().substr($this.caret(), 1)
        previous_char = $this.val().substr($this.caret()-1, 1)
        is_last_char = current_char.match(/\s/) || current_char.trim() == ""
        
        # Arrows
        if $j(".move").hasClass("selected")
          e.preventDefault() if e.keyCode == 38 || e.keyCode == 40 || e.keyCode == 13
          if e.keyCode == 13
            $j(".move").removeClass("selected")
            return false
        
        # Enter?
        if (e.keyCode == 13 && (!e.altKey || e.ctrlKey)) || (data && data.newline)
          if current_line.trim() == "" || (previous_line != undefined && previous_line.trim() == "")
            e.preventDefault()
          else
            # Indent
            indent = lines[line].match(/^[\t]*/g)[0]
            caret = $this.caret()
            text = $this.val().insert(caret, "\n#{indent}")
            $this.val(text)
            $this.caret(caret + "\n#{indent}".length)
            e.preventDefault()
        
        # Tab?
        else if e.keyCode == 9
          e.preventDefault()
          App.chart.indent(!e.shiftKey)
          
        # Space?
        else if e.keyCode == 32
          if is_last_char
            e.preventDefault()
        
        # Open person
        if current_line.trim().match(/^@(.+)/) && is_last_char && (e.keyCode == 8 || e.keyCode == 46)
          App.chart.person(current_line.trim(), true)
          e.preventDefault()
        
        true
        
      $j(".edit_chart textarea").bind "keyup", (e) ->
        $this = $j(this)
        
        # Enter?
        # if e.keyCode == 13
        #   App.chart.update()
          
        # Arrows
        if $j(".move").hasClass("selected") && (e.keyCode == 38 || e.keyCode == 40)
          line = $this.caretLine() - 1
          lines = $this.val().split("\n")
          caret = $this.caret()
          
          selected = (for current, idx in lines
            break if idx > line && current.level() <= lines[line].level()
            do (line) ->
              idx if idx > line && current.level() > lines[line].level()
          ).filter (x) -> x
          selected.unshift line
          
          if e.keyCode == 38
            # Up
            if lines[line-1] != undefined
              caret = caret - lines[line-1].length - 1
              for idx in selected
                swap = lines[idx-1]
                lines[idx-1] = lines[idx]
                lines[idx] = swap
          
          else if e.keyCode == 40
            # Down
            selected = selected.reverse()
            line = selected[0]
            if lines[line+1] != undefined
              caret = caret + lines[line+1].length + 1
              for idx in selected
                swap = lines[idx+1]
                lines[idx+1] = lines[idx]
                lines[idx] = swap
          
          $this.val(lines.join("\n"))
          $this.caret(caret)
        
        # Render lines
        App.chart.lines()
      
      # Render lines first time
      App.chart.lines()
      
      # Autosize
      $j(".edit_chart textarea").autosize()
      $j(".edit_chart textarea").css("minHeight", $j(".left").height()-parseInt($j(".left .text").css("top")))
      
      $j(".edit_chart").unbind "submit"
      $j(".edit_chart").bind "submit", ->
        $j(window).unbind "beforeunload"
        App.chart.update()
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
          
      # Sidebar resize
      $j(".btn-divider").unbind "mousedown"
      $j(".btn-divider").bind "mousedown", (e) ->
        width = parseInt($j("[name='chart[sidebar]']").val())
        App.chart.sidebarWidth = width unless width == 0
        App.chart.sidebarDragged = false
        
      $j(".btn-divider").unbind "mouseup"
      $j(".btn-divider").bind "mouseup", (e) ->
        # Previous width
        if App.chart.sidebarWidth
          if parseInt($j("[name='chart[sidebar]']").val()) != 0
            width = 0
          else
            width = App.chart.sidebarWidth
          
          App.chart.sidebar(width)
        
        # Default width
        else if !App.chart.sidebarDragged && parseInt($j("[name='chart[sidebar]']").val()) == 0
          App.chart.sidebar(400)
      
      $j(".btn-divider").draggable("destroy") if $j(".btn-divider").hasClass("ui-draggable")
      $j(".btn-divider").draggable
        axis: "x"
        drag: (e, ui) ->
          # Clear sidebarWidth
          App.chart.sidebarWidth = null
          App.chart.sidebarDragged = true
          
          sidebar = Math.max(0, Math.min($j("html").width()-13, ui.offset.left))
          $j(".left, .editor").css(width: sidebar)
          $j(".right, .btn-divider").css(left: sidebar)
          $j("[name='chart[sidebar]']").val(sidebar)
          
          clearTimeout(App.chart.sidebarTimeout) if App.chart.sidebarTimeout
          App.chart.sidebarTimeout = setTimeout ->
            App.chart.sidebar(sidebar)
          , 500
          
          return false if ui.offset.left != sidebar
          
      # Help
      $j(".editor .help .btn, .editor .help .close").unbind "click"
      $j(".editor .help .btn, .editor .help .close").bind "click", ->
        $j.cookie("help", true, { path: "/", expires: 365 })
        $j(".editor .help").toggleClass("open")
        false
      
    check: ->
      if $j(".edit_chart").length > 0 && !App.chart.skip
        App.chart.update(false)
    
    click: (id) ->
      node = App.chart.chart?.nodes_as_hash[id]
      if node
        # Show person
        if node.title.match(/^@/)
          App.chart.person(node.title)
        # Go to node
        else
          # Set skip to prevent saving
          App.chart.skip = true
          Turbolinks.visit("/charts/#{App.chart.chart.slug}/nodes/#{id}")
    
    person: (title, focus = false) ->
      App.loading(true)
      
      $j.ajax url: "/charts/#{App.chart.chart.slug}/persons/#{encodeURIComponent(title)}/edit", type: "GET", complete: (data) ->
        # Editable
        if $j(".edit_chart textarea").length > 0
          $overlay = $j(data.responseText)
          $overlay.appendTo("body")
          App.chart.autocomplete.show($overlay)
        else
          Mousetrap.bind "esc", ->
            $j(".overlay.person .cancel").trigger "click"
            
          $j(".overlay.person .content").html(data.responseText)
          $j(".overlay.person").show()
          $j(".overlay.person .box").css(marginTop: -$j(".overlay.person .box").height()/2)
          
          $j(".overlay.person textarea").focus() if focus
          $j(".overlay.person textarea").unbind "keydown"
          $j(".overlay.person textarea").bind "keydown", (e) ->
            if e.keyCode == 27
              Mousetrap.trigger "esc"
              e.preventDefault()
          
        App.loading(false)
      
    
    update: (current = true) ->
      $form = $j(".edit_chart")
      return if $form.attr("data-saving") || App.chart.status.text() != I18n.t("charts.autosave.changed")
      
      App.chart.status.text(I18n.t("charts.autosave.saving"))
      if current
        $j("header figure .icon").addClass("hidden")
        $j("header figure .filled").removeClass("hidden")
        $j("header figure .saving").removeClass("hidden")
      $form.attr("data-saving", true)
      
      $j.ajax(url: $form.attr("action"), data: $form.serialize(), dataType: "json", type: $form.attr("method"))
        .always ->
          $form.attr("data-saving", null)
          $j("header figure .saving").addClass("hidden")
        
        .error (xhr, status, error) ->
          App.chart.status.text(I18n.t("charts.autosave.error"))
          $j("header figure .icon").addClass("hidden")
          $j("header figure .error").removeClass("hidden")
        
        .done (result) ->
          if result.redirect_to
            # Replace state
            if window.history and window.history.pushState and window.history.replaceState and window.history.state != undefined
              window.history.replaceState window.history.state, '', result.redirect_to
          
          if result.action_to
            $form.attr("action", result.action_to)
          
          if result.pdf_to
            $j(".pdf").attr("href", result.pdf_to)
            
          # Reload
          if !current
            Turbolinks.visit(document.location.href)
            return
          
          if result.chart
            # Replace breadcrumb
            $j(".breadcrumb").html(result.breadcrumb) if result.breadcrumb
            App.chart.breadcrumb()
            
            # Replace header
            $j(".chart .header").html(result.header) if result.header
            App.chart.resize()
            
            # Show
            $j("[data-chart]").attr("data-chart", JSON.stringify(result.chart))
            App.chart.show($j("[data-chart]"))
            
            if App.chart.status.text() != I18n.t("charts.autosave.changed")
              App.chart.status.text(I18n.t("charts.autosave.saved"))
            
            $j("header figure .icon").addClass("hidden")
            $j("header figure .default").removeClass("hidden")
          else
            App.chart.status.text(I18n.t("charts.autosave.error"))
            if current
              $j("header figure .icon").addClass("hidden")
              $j("header figure .error").removeClass("hidden")
        
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
    
$j ->
  # Turbolinks
  $j(document).live "page:fetch", ->
    App.chart.check()
    App.loading(true)
  $j(document).live "page:change", ->
    App.chart.skip = false
    App.loading($j("[data-not-loaded]").length != 0)
    App.init()
  
  App.init()
  window.App = App