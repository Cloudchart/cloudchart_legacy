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
    
    init: ->
      App.chart.resize = (timeout = 500) ->
        # Fill height
        $j(".chart, .chart .left, .chart .canvas, #canvas div:eq(0)").css(
          "height",
          Math.max(250, $j("html").height() - $j("header").outerHeight() - $j(".breadcrumb").outerHeight())
        )
        
        if $j(".edit_chart textarea").length > 0
          # Autosize
          $j(".edit_chart textarea").css("minHeight", $j(".left").height()-parseInt($j(".left .text").css("top")))
          
          # Editor lines
          sidebarTimeout = ->
            App.chart.cache.breaks = {}
            App.chart.lines()
            
            # Sidebar width
            if $j("[name='chart[sidebar]']").length > 0
              sidebar = Math.max(0, Math.min($j("html").width()-13, parseInt($j("[name='chart[sidebar]']").val())))
              $j(".left, .editor").css(width: sidebar)
              $j(".right, .btn-divider").css(left: sidebar)
              App.chart.cache.breaks = {}
              App.chart.lines()
          
          clearTimeout(App.chart.sidebarTimeout) if App.chart.sidebarTimeout
          if timeout > 0
            App.chart.sidebarTimeout = setTimeout(sidebarTimeout, timeout)
          else
            sidebarTimeout()
      
      App.chart.resize(0)
      $j(window).unbind "resize"
      $j(window).bind "resize", -> App.chart.resize()
      
      # Canvas
      App.canvas = new Canviz("canvas") if $j("#canvas").length > 0
      
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
        
      # Breadcrumb
      $j(".breadcrumb .active a").popover
        my: "center top",
        at: "center bottom",
        offset: "0 18px"
      
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
          $j(".overlay.share button.copy").unbind "click"
          $j(".overlay.share button.copy").bind "click", (e) ->
            if navigator.userAgent.match(/iPad|iPhone|iPod/i) != null
              e.preventDefault()
              window.open $j(this).parent().find(":first").find("input").val()
            return false
          
          $j(".overlay.share button.copy").zclip
            path: "/zero.swf"
            copy: ->
              $j(this).attr("data-clipboard-text")
            afterCopy: ->
              $this = $j(this)
              $input = $this.prev().find("input")
              $email = $this.next()
              
              if $email.hasClass("progress")
                if $input.val().strip() != ""
                  $email.removeClass("pressme")
                  $email.addClass("disabled")
                  $email.text($email.attr("data-enter"))
                  $input.val("")
                  return false
                
                $email.removeClass("disabled")
                $email.removeClass("pressme")
                $email.removeClass("progress")
                $this.text($this.attr("data-text"))
                $email.text($email.attr("data-text"))
                $input.attr("placeholder", $input.attr("data-placeholder"))
                return false
          
        )
        
        false
      
      $j(".overlay .cancel").unbind "click"
      $j(".overlay .cancel").bind "click", ->
        Mousetrap.unbind "esc"
        $j(this).closest(".overlay").fadeOut ->
          $j(this).hide()
      
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
              $input.val("")
              $input.attr("placeholder", $input.attr("data-placeholder"))
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
          
          if $input.val().strip() != ""
            $this.addClass("pressme")
            $this.text($this.attr("data-send"))
          else
            $this.addClass("disabled")
            $this.text($this.attr("data-enter"))
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
          $email.text($email.attr("data-enter"))
        
      # Rename
      $j("header .btn-rename").bind "click", ->
        $form = $j(".edit_chart")
        title = prompt(I18n.t("charts.rename.descr"), $form.find("[name='chart[title]']").val())
        title = title.strip() if title
        
        if title && title != ""
          App.chart.status.text(I18n.t("charts.autosave.changed"))
          $form.find("[name='chart[title]']").val(title)
          $j("header .chart-title").text(title)
          
          App.chart.update true, ->
            Turbolinks.visit(document.location.href)
        
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
    
    lines: ->
      $this = $j(".edit_chart textarea")
      
      lines = $this.val().split("\n")
      levels = {}
      
      list = for line in lines
        num = _i + 1
        
        level = line.match(/^[\t]*/g)[0].length
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
      
      prev_line_level = (lines[indent[0]-1] || "").match(/^[\t]*/g)[0].length
      first_line_level = lines[indent[0]].match(/^[\t]*/g)[0].length
      last_line_level = lines[indent[indent.length-1]].match(/^[\t]*/g)[0].length
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
            data = $this.data("person")
            $overlay.find(".loading").show()
            
            $j.ajax url: "/charts/#{App.chart.chart.slug}/persons/#{encodeURIComponent("@#{data.val}")}/profile", type: "GET", complete: (data) ->
              $overlay.find(".profile").html(data.responseText).show()
              $overlay.find(".buttons").hide()
              $overlay.find(".buttons.for-profile").show()
              $overlay.find(".list").hide()
              $overlay.find(".loading").hide()
          else
            App.chart.autocomplete.select_current($j(this))
      
      select_current: ($current) ->
        $overlay = $j(".overlay.persons")
        $current = $j(".overlay.persons .list li:first") unless $current
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
            $overlay = $j(".overlay.persons")
            $input = $overlay.find("[name='person[q]']")
            
            App.chart.autocomplete.current = null
            $overlay.find("form").unbind "submit"
            $overlay.find(".fire").unbind "click"
            $overlay.find(".return").unbind "click"
            
            $input.val("@")
            $input.unbind "textchange"
            $input.bind "textchange", ->
              # Hide profile
              if $overlay.find(".profile").is(":visible")
                Mousetrap.trigger "esc"
              
              # Clear current
              $overlay.find(".list").empty()
              App.chart.autocomplete.select_current()
            
            $input.unbind "keydown"
            $input.bind "keydown", (e) ->
              return Mousetrap.trigger("up") && false if e.keyCode == 38
              return Mousetrap.trigger("down") && false if e.keyCode == 40
              return Mousetrap.trigger("esc") && false if e.keyCode == 27
            
            $input.unbind "keyup"
            $input.bind "keyup", (e) ->
              return false if e.keyCode == 13
              autocomplete = App.chart.autocomplete
              
              # Close
              if $input.val() == ""
                # Clear current
                $overlay.find(".list").empty()
                autocomplete.select_current()
                
                $overlay.find(".for-list .fire").trigger "click"
              
              # Search
              autocomplete.cache = {} unless autocomplete.cache
              clearTimeout(autocomplete.timeout) if autocomplete.timeout
              if autocomplete.cache[$input.val()]
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
                      autocomplete.select_current()
              , if e.keyCode then 1000 else 0)
              false
            $input.trigger "keyup"
            
            # Fade in
            (->
              $overlay.show()
              $input.focus()
              
              Mousetrap.bind "enter", ->
                $overlay.find(".for-list .fire").trigger "click"
              
              Mousetrap.bind "esc", ->
                if $overlay.find(".profile").is(":visible")
                  $overlay.find(".profile").empty().hide()
                  $overlay.find(".buttons").hide()
                  $overlay.find(".buttons.for-list").show()
                  $overlay.find(".list").show()
                
                else if $input.val() != "@"
                  $input.val("@")
                  $input.trigger "keyup"
                else
                  # Clear current
                  $input.val("")
                  $overlay.find(".list").empty()
                  App.chart.autocomplete.select_current()
                  
                  $overlay.find(".for-list .fire").trigger "click"
              
              Mousetrap.bind "up", ->
                $list = $j(".overlay.persons .list")
                $selected = $list.find(".selected")
                if $selected.prev().length == 1
                  App.chart.autocomplete.select_current($selected.prev())
                else
                  App.chart.autocomplete.select_current($overlay.find(".list li:last"))
                
                $list.scrollTo(".selected", 100)
              
              Mousetrap.bind "down", ->
                $list = $j(".overlay.persons .list")
                $selected = $list.find(".selected")
                if $selected.next().length == 1
                  App.chart.autocomplete.select_current($selected.next())
                else
                  App.chart.autocomplete.select_current($overlay.find(".list li:first"))
                
                $list.scrollTo(".selected", 100)
              
              $overlay.find("form").bind "submit", ->
                $overlay.find(".for-list .fire").trigger "click"
                false
              
              $overlay.find(".return").bind "click", ->
                Mousetrap.trigger "esc"
                false
              
              $overlay.find(".fire").bind "click", ->
                not_now = false
                if !App.chart.autocomplete.current && $overlay.find(".list li").length > 0
                  # Select current
                  App.chart.autocomplete.select_current()
                  not_now = true
                
                if $input.val() == "" || (App.chart.autocomplete.current && !not_now) || $overlay.find(".list li").length == 0
                  # Hide profile
                  if $overlay.find(".profile").is(":visible")
                    Mousetrap.trigger "esc"
                  
                  Mousetrap.unbind "enter"
                  Mousetrap.unbind "esc"
                  Mousetrap.unbind "up"
                  Mousetrap.unbind "down"
                  
                  caret = $this.caret()
                  if App.chart.autocomplete.current
                    append = App.chart.autocomplete.current.val
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
                  App.chart.autocomplete.select_current()
                  
                  $overlay.hide()
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
      
      # Buttons
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
      
      $j(".buttons .left-indent").bind "click", ->
        App.chart.indent(false)
        App.chart.lines()
        false
      
      $j(".buttons .right-indent").bind "click", ->
        App.chart.indent(true)
        App.chart.lines()
        false
      
      $j(".buttons .move").bind "click", ->
        $j(this).toggleClass("selected")
        $area = $j(".edit_chart textarea")
        $area.caret($area.caret())
        false
      
      # Key event
      $j(".edit_chart textarea").unbind "keydown"
      $j(".edit_chart textarea").bind "keydown", (e, data) ->
        $this = $j(this)
        
        # Enter?
        if e.keyCode == 13 || (data && data.newline)
          line = $this.caretLine() - 1
          lines = $this.val().split("\n")
          
          if lines[line].trim() == "" || (lines[line-1] != undefined && lines[line-1].trim() == "")
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
          prev = $this.val().substr($this.caret()-1, 1)
          if $this.caret() == 0 || prev == "\n" || prev == "\t"
            e.preventDefault()
        
        # Arrows
        if $j(".move").hasClass("selected")
          e.preventDefault() if e.keyCode == 38 || e.keyCode == 40
        
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
          if e.keyCode == 38
            # Up
            if lines[line-1] != undefined
              swap = lines[line-1]
              lines[line-1] = lines[line]
              lines[line] = swap
              caret = caret - swap.length - 1
          
          else if e.keyCode == 40
            # Down
            if lines[line+1] != undefined
              swap = lines[line+1]
              lines[line+1] = lines[line]
              lines[line] = swap
              caret = caret + swap.length + 1
          
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
        
      $j(".btn-divider").unbind "mouseup"
      $j(".btn-divider").bind "mouseup", (e) ->
        if App.chart.sidebarWidth
          if parseInt($j("[name='chart[sidebar]']").val()) != 0
            width = 0
          else
            width = App.chart.sidebarWidth
          
          sidebar = Math.max(0, Math.min($j("html").width()-13, width))
          $j(".left, .editor").css(width: sidebar)
          $j(".right, .btn-divider").css(left: sidebar)
          $j("[name='chart[sidebar]']").val(sidebar)
      
      $j(".btn-divider").draggable
        axis: "x"
        drag: (e, ui) ->
          # Clear sidebarWidth
          App.chart.sidebarWidth = null
          
          sidebar = Math.max(0, Math.min($j("html").width()-13, ui.offset.left))
          $j(".left, .editor").css(width: sidebar)
          $j(".right, .btn-divider").css(left: sidebar)
          $j("[name='chart[sidebar]']").val(sidebar)
          
          clearTimeout(App.chart.sidebarTimeout) if App.chart.sidebarTimeout
          App.chart.sidebarTimeout = setTimeout ->
            App.chart.cache.breaks = {}
            App.chart.lines()
          , 500
          
          return false if ui.offset.left != sidebar
      
    check: ->
      if $j(".edit_chart").length > 0 && !App.chart.skip
        App.chart.update(false)
    
    click: (id) ->
      node = App.chart.chart?.nodes_as_hash[id]
      if node
        # Show person
        if node.title.match(/^@/)
          App.loading(true)
          
          $j.ajax url: "/charts/#{App.chart.chart.slug}/persons/#{encodeURIComponent(node.title)}/profile", type: "GET", complete: (data) ->
            Mousetrap.bind "esc", ->
              $j(".overlay.person .cancel").trigger "click"
              
            $j(".overlay.person .content").html(data.responseText)
            $j(".overlay.person").show()
            $j(".overlay.person .box").css(marginTop: -$j(".overlay.person .box").height()/2)
            App.loading(false)
        
        # Go to node
        else
          # Set skip to prevent saving
          App.chart.skip = true
          if $j(".canvas").attr("data-action") == "edit"
            Turbolinks.visit("/charts/#{App.chart.chart.slug}/nodes/#{id}/edit")
          else
            Turbolinks.visit("/charts/#{App.chart.chart.slug}/nodes/#{id}")
    
    update: (current = true, callback = null) ->
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
          # Reload
          if !current
            Turbolinks.visit(document.location.href)
            return
          
          if result.redirect_to
            # Replace state
            if window.history and window.history.pushState and window.history.replaceState and window.history.state != undefined
              window.history.replaceState window.history.state, '', result.redirect_to
          
          if result.action_to
            $form.attr("action", result.action_to)
            
          if result.chart
            # Show
            $j("[data-chart]").attr("data-chart", JSON.stringify(result.chart))
            App.chart.show($j("[data-chart]"))
            
            if App.chart.status.text() != I18n.t("charts.autosave.changed")
              App.chart.status.text(I18n.t("charts.autosave.saved"))
            
            $j("header figure .icon").addClass("hidden")
            $j("header figure .default").removeClass("hidden")
            
            # Callback?
            callback() if callback
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
          false
    
    reload: ->
      document.location.href = "/" if document.location.href.match(/beta/)
      
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
    App.chart.skip = false
    App.loading($j("[data-not-loaded]").length != 0)
    App.init()
  
  App.init()
  window.App = App