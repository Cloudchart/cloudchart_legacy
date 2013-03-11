$      = jQuery
root   = @

scope  = 
  cache:
    breaks: {}
  
  store: (chart) ->
    if !chart.user_id
      charts = if $j.cookie("charts") then JSON.parse($j.cookie("charts")) else {}
      charts[chart.id] = { id: chart.id, token: chart.token }
      $j.cookie("charts", JSON.stringify(charts), { path: "/", expires: 365 })
  
  demo: ($this) ->
    root.chart.show($this)
  
  create: (href = "/charts") ->
    App.loading(true)
    $j.ajax url: href, dataType: "json", type: "POST", complete: (data) ->
      result = eval "(#{data.responseText})"
      root.chart.store(result.chart)
      Turbolinks.visit(result.redirect_to)
  
  show: ($this) ->
    root.chart.chart = JSON.parse($this.attr("data-chart"))
    $j(".canvas").css("overflow", "none")
    App.canvas.parse(root.chart.chart.xdot)
    root.chart.resize()
    $j(".canvas").css("overflow", "auto")
  
  init: ->
    root.chart.resize(0)
    $j(window).unbind "resize"
    $j(window).bind "resize", -> root.chart.resize()
    
    # Canvas
    App.canvas = new Canviz("canvas") if $j("#canvas").length > 0
    
    # Breadcrumb
    root.chart.breadcrumb()
    
    # Create button
    $j(".create").unbind "click"
    $j(".create").bind "click", ->
      root.chart.create()
      false
    
    # Clone button
    $j(".clone").unbind "click"
    $j(".clone").bind "click", ->
      root.chart.create($j(this).attr("href"))
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
        root.chart.status.text(I18n.t("charts.autosave.changed"))
        root.chart.update()
      
    
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
        root.chart.status.text(I18n.t("charts.autosave.changed"))
        $form.find("[name='chart[title]']").val(title)
        $j("header .chart-title").text(title)
        
        root.chart.update(false)
      
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
      root.chart.check()
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
        root.chart.status.text(I18n.t("charts.autosave.changed"))
        $j("[name='chart[sidebar]']").val(sidebar)
    else if $j("[name='chart[sidebar]']").length > 0
      sidebar = Math.max(0, Math.min($j("html").width()-13, parseInt($j("[name='chart[sidebar]']").val())))
    else
      sidebar = 0
    
    $j(".left, .editor").css(width: sidebar)
    $j(".right, .btn-divider").css(left: sidebar)
    
    # Editor lines
    root.chart.cache.breaks = {}
    root.chart.lines()
    root.chart.update()
  
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
    clearTimeout(root.chart.sidebarTimeout) if root.chart.sidebarTimeout
    if timeout > 0
      root.chart.sidebarTimeout = setTimeout(root.chart.sidebar, timeout)
    else
      root.chart.sidebar()
  
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
      
      if root.chart.cache.breaks[text]
        breaks = root.chart.cache.breaks[text]
      else
        width = $this.textWidth(text)
        breaks = root.chart.cache.breaks[text] = Math.ceil((width + 1) / $this.width())
      
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
  
  # TODO: Speedup - ?
  edit: ($this) ->
    root.chart.status = $j(".edit_chart h3")
    clearInterval(root.chart.interval) if root.chart.interval
    root.chart.interval = setInterval( ->
      root.chart.update()
    , 10000)
    
    # Autocomplete
    root.autocomplete.bindings()
    
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
      root.chart.indent(false)
      root.chart.lines()
      false
    
    $j(".buttons .right-indent").unbind "click"
    $j(".buttons .right-indent").bind "click", ->
      root.chart.indent(true)
      root.chart.lines()
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
      
      # Arrows in move mode
      if $j(".move").hasClass("selected")
        e.preventDefault() if e.keyCode == 38 || e.keyCode == 40 || e.keyCode == 13
        if e.keyCode == 13
          $j(".move").removeClass("selected")
          return false
      
      # Arrows in normal mode
      if e.keyCode == 38 || e.keyCode == 40 || e.keyCode == 37 || e.keyCode == 39
        return true
      
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
        
        return true
      
      # Tab?
      else if e.keyCode == 9
        e.preventDefault()
        root.chart.indent(!e.shiftKey)
        return true
        
      # Open person
      if current_line.trim().match(/^@(.+)/) && is_last_char && (!e.altKey && !e.ctrlKey && !e.shiftKey && !e.metaKey)
        root.chart.person(current_line.trim(), true)
        e.preventDefault()
      
      true
      
    $j(".edit_chart textarea").bind "keyup", (e) ->
      $this = $j(this)
      
      # Enter?
      # if e.keyCode == 13
      #   root.chart.update()
        
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
      root.chart.lines()
    
    # Render lines first time
    root.chart.lines()
    
    # Autosize
    $j(".edit_chart textarea").autosize()
    $j(".edit_chart textarea").css("minHeight", $j(".left").height()-parseInt($j(".left .text").css("top")))
    
    $j(".edit_chart").unbind "submit"
    $j(".edit_chart").bind "submit", ->
      $j(window).unbind "beforeunload"
      root.chart.update()
      return true
    
    $j(".edit_chart textarea, .edit_chart input").unbind "textchange"
    $j(".edit_chart textarea, .edit_chart input").bind "textchange", ->
      root.chart.status.text(I18n.t("charts.autosave.changed"))
    
    $j(window).unbind "beforeunload"
    $j(window).bind "beforeunload", (e) ->
      e = e || window.event
      msg = I18n.t("charts.autosave.lost");
      
      if root.chart.status.text() == I18n.t("charts.autosave.changed")
        # For IE and Firefox prior to version 4
        if e
          e.returnValue = msg
        
        # For Safari
        return msg
        
    # Sidebar resize
    $j(".btn-divider").unbind "mousedown"
    $j(".btn-divider").bind "mousedown", (e) ->
      width = parseInt($j("[name='chart[sidebar]']").val())
      root.chart.sidebarWidth = width unless width == 0
      root.chart.sidebarDragged = false
      
    $j(".btn-divider").unbind "mouseup"
    $j(".btn-divider").bind "mouseup", (e) ->
      # Previous width
      if root.chart.sidebarWidth
        if parseInt($j("[name='chart[sidebar]']").val()) != 0
          width = 0
        else
          width = root.chart.sidebarWidth
        
        root.chart.sidebar(width)
      
      # Default width
      else if !root.chart.sidebarDragged && parseInt($j("[name='chart[sidebar]']").val()) == 0
        root.chart.sidebar(400)
    
    $j(".btn-divider").draggable("destroy") if $j(".btn-divider").hasClass("ui-draggable")
    $j(".btn-divider").draggable
      axis: "x"
      drag: (e, ui) ->
        # Clear sidebarWidth
        root.chart.sidebarWidth = null
        root.chart.sidebarDragged = true
        
        sidebar = Math.max(0, Math.min($j("html").width()-13, ui.offset.left))
        $j(".left, .editor").css(width: sidebar)
        $j(".right, .btn-divider").css(left: sidebar)
        $j("[name='chart[sidebar]']").val(sidebar)
        
        clearTimeout(root.chart.sidebarTimeout) if root.chart.sidebarTimeout
        root.chart.sidebarTimeout = setTimeout ->
          root.chart.sidebar(sidebar)
        , 500
        
        return false if ui.offset.left != sidebar
        
    # Help
    $j(".editor .help .btn, .editor .help .close").unbind "click"
    $j(".editor .help .btn, .editor .help .close").bind "click", ->
      $j.cookie("help", true, { path: "/", expires: 365 })
      $j(".editor .help").toggleClass("open")
      false
    
  check: ->
    if $j(".edit_chart").length > 0 && !root.chart.skip
      root.chart.update(false)
  
  click: (id) ->
    node = root.chart.chart?.nodes_as_hash[id]
    if node
      # Show person
      if node.title.match(/^@/)
        root.chart.person(node.title)
      # Go to node
      else
        # Set skip to prevent saving
        root.chart.skip = true
        Turbolinks.visit("/charts/#{root.chart.chart.slug}/nodes/#{id}")
  
  person: (title, focus = false) ->
    App.loading(true)
    
    $j.ajax url: "/charts/#{root.chart.chart.slug}/persons/#{encodeURIComponent(title)}/edit", type: "GET", complete: (data) ->
      # Editable, show autocomplete
      if $j(".edit_chart textarea").length > 0
        $overlay = $j(data.responseText)
        $overlay.appendTo("body")
        root.autocomplete.show($overlay)
      
      # Showable
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
    return if $form.attr("data-saving") || root.chart.status.text() != I18n.t("charts.autosave.changed")
    
    root.chart.status.text(I18n.t("charts.autosave.saving"))
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
        root.chart.status.text(I18n.t("charts.autosave.error"))
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
          root.chart.breadcrumb()
          
          # Replace header
          $j(".chart .header").html(result.header) if result.header
          root.chart.resize()
          
          # Show
          $j("[data-chart]").attr("data-chart", JSON.stringify(result.chart))
          root.chart.show($j("[data-chart]"))
          
          if root.chart.status.text() != I18n.t("charts.autosave.changed")
            root.chart.status.text(I18n.t("charts.autosave.saved"))
          
          $j("header figure .icon").addClass("hidden")
          $j("header figure .default").removeClass("hidden")
        else
          root.chart.status.text(I18n.t("charts.autosave.error"))
          if current
            $j("header figure .icon").addClass("hidden")
            $j("header figure .error").removeClass("hidden")

$.extend root,
  chart: scope