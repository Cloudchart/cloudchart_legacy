# Navigation
$(document).on("click", "[data-behavior=toggle-navigation]", (e) ->
  $target = $(e.target)
  if $target.closest("[data-skip-toggle]").length > 0
    return true
  
  if !$("[data-behavior=navigation]").is(":visible")
    $("[data-behavior=navigation]").stop().slideDown()
    $("[data-behavior=navigation-overlay]").stop().fadeIn()
    $("[data-behavior=toggle-with-navigation]").stop().fadeIn()
    # $("[data-behavior=toggle-inline-with-navigation]").stop().css("opacity", 0).css("display", "inline-block").animate(opacity: 1)
    $("[data-behavior=toggle-inline-with-navigation]").css("display", "inline-block")
  else
    $("[data-behavior=navigation]").stop().slideUp()
    $("[data-behavior=navigation-overlay]").stop().fadeOut()
    $("[data-behavior=toggle-with-navigation]").stop().fadeOut()
    # $("[data-behavior=toggle-inline-with-navigation]").stop().fadeOut()
    $("[data-behavior=toggle-inline-with-navigation]").css("display", "none")
  
  false
)

$(document).on("click", "[data-behavior=navigation-overlay]", (e) ->
  $("[data-behavior=toggle-navigation]").trigger("click")
)

# Form helpers
$(document).on("click", "[data-behavior$=-edit] [data-behavior=fieldset] [data-behavior=new]", ->
  $template = $(this).closest("[data-behavior=fieldset]").find("[data-behavior=template]").clone()
  $sets = $(this).closest("[data-behavior=fieldset]").find("[data-behavior=sets]")
  
  index = Math.max($.map($(this).closest("[data-behavior=fieldset]").find("[data-behavior=index]"), (v) ->
    value = $(v).html()
    if value != "" then parseInt(value) else 0
  )...) + 1
  
  $template.removeClass("hidden")
  $template.attr("data-behavior", "container")
  $template.find("[data-behavior=index]").text(index)
  $template.find("[data-behavior=set]").show()
  $template.find("input").each(->
    $this = $(this)
    $this.attr("name", $this.attr("name").replace("%i", index))
  )
  
  $template.appendTo($sets)
  false
)

$(document).on("click", "[data-behavior$=-edit] [data-behavior=fieldset] [data-behavior=set-destroy]", ->
  $container = $(this).closest("[data-behavior=container]")
  $container.remove()
  
  false
)

$(document).on("click", "[data-behavior$=-edit] [data-behavior=fieldset] [data-behavior=set-edit]", ->
  $preview = $(this).closest("[data-behavior=preview]")
  $set = $preview.closest("[data-behavior=container]").find("[data-behavior=set]")
  
  $preview.hide()
  $set.show()
  
  false
)

# General initialization
$ ->
  $("textarea[data-autosize]").autosize()
