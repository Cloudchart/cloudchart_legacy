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
//= require jquery/sew
# Other
//= require turbolinks
//= require turbolinks-analytics
//= require i18n
//= require i18n/translations
//= require twitter/bootstrap
//= require mousetrap
//= require underscore
//= require jquery/popover
//= require jquery/touch-punch

$j = jQuery.noConflict()
window.$j = $j

App = 
  loading: (flag) ->
    if flag
      # height = if $j("footer").length > 0 then $j("footer").offset().top else $j("html").height() - $j("header").height()
      # $j(".loading .bar").css(top: Math.min(height/2, ($j("html").height() - $j("header").height())/2) - $j(".loading .bar").height()/2)
      # $j(".loading").css(height: height).show()
      $j(".loading").show()
    else
      $j(".loading").hide()
  
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
          $j(".edit_chart textarea").css("minHeight", $j(".left").height()-34)
          
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
      $j("header .context").unbind "click"
      $j("header .context").bind "click", ->
        $j(this).toggleClass("active")
        src = $j(this).find("img").attr("src")
        if src.match(/arrow/)
          if $j(this).hasClass("active")
            $j(this).find("img").attr("src", $j(this).attr("data-selected"))
          else
            $j(this).find("img").attr("src", $j(this).attr("data-normal"))
        
      $j("header .context").popover
        my: "center top",
        at: "center bottom",
        offset: "0 -1px"
        
      # Context buttons and overlays
      $j("header .btn-share, header .btn-history, header .btn-delete").unbind "click"
      $j("header .btn-share, header .btn-history, header .btn-delete").bind "click", ->
        cls = $j(this).attr("class").replace("btn-", "")
        
        $j(".popover").hide()
        if $j(".context:visible img").attr("src").match(/arrow/)
          $j(".context:visible img").attr("src", $j(".context").attr("data-normal"))
        
        $j(".overlay.#{cls}").fadeIn()
        false
      
      $j(".overlay .cancel").unbind "click"
      $j(".overlay .cancel").bind "click", ->
        $j(this).closest(".overlay").fadeOut ->
          $j(this).hide()
      
      # Rename
      $j("header .btn-rename").unbind "click"
      $j("header .btn-rename").bind "click", ->
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
      
    # TODO: Speedup - ?
    # TODO: Autosave - ?
    edit: ($this) ->
      App.chart.status = $j(".edit_chart h3")
      clearInterval(App.chart.interval) if App.chart.interval
      App.chart.interval = setInterval( ->
        App.chart.update()
      , 10000)
      
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
      $j(".edit_chart textarea").bind "keydown", (e) ->
        $this = $j(this)
        
        # Enter?
        if e.keyCode == 13
          return true if $j(".-sew-list-container").is(":visible")
          
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
        
      $j(".edit_chart textarea").unbind "keyup"
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
      $j(".edit_chart textarea").css("minHeight", $j(".left").height()-34)
      
      # Autocomplete
      $j(".edit_chart textarea").sew
        values: (sew, callback) ->
          sew.cache = {} unless sew.cache
          if sew.cache[sew.options.val]
            callback.call(sew, sew.cache[sew.options.val])
            return true
          
          return false if sew.options.loading
          
          clearTimeout(sew.options.timeout) if sew.options.timeout
          sew.options.timeout = setTimeout(->
            $this = $j(".edit_chart textarea")
            sew.options.loading = true
            
            cache_key = sew.options.val
            $j.ajax(url: $this.attr("data-autocomplete"), data: { q: sew.options.val }, dataType: "json", type: "GET")
              .always ->
                sew.options.loading = false
              
              .error (xhr, status, error) ->
                console.error error
              
              .done (result) ->
                values = _.map(result.persons, (x) ->
                  name = "#{x.first_name} #{x.last_name}"
                  { val: "#{name}(ln:#{x.id})", name: name, headline: x.headline, picture: x.picture_url }
                )
                sew.cache[cache_key] = values
                callback.call(sew, values) if cache_key == sew.options.val
          , 250)
          false
          
        
        elementFactory: (element, e) ->
          image = if e.picture then e.picture else "/images/ico-person.png"
          element.append(
            "<div><img src='#{image}'><h3>#{e.name}</h3><p>#{e.headline}</p></div>"
          )
      
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
      if $j(".edit_chart").length > 0
        App.chart.update(false)
    
    click: (id) ->
      Turbolinks.visit("/charts/#{App.chart.chart.slug}/nodes/#{id}/edit")
    
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