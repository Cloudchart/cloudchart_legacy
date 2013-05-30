# Navigation
$(document).on("click", "[data-behavior=toggle-navigation]", (e) ->
  $target = $(e.target)
  if $target.closest("[data-skip-toggle]").length > 0
    return true
  
  if !$("[data-behavior=navigation]").is(":visible")
    $("[data-behavior=navigation]").slideDown()
    $("[data-behavior=navigation-overlay]").fadeIn()
    $("[data-behavior=toggle-with-navigation]").fadeIn()
    # $("[data-behavior=toggle-inline-with-navigation]").css("opacity", 0).css("display", "inline-block").animate(opacity: 1)
    $("[data-behavior=toggle-inline-with-navigation]").css("display", "inline-block")
  else
    $("[data-behavior=navigation]").slideUp()
    $("[data-behavior=navigation-overlay]").fadeOut()
    $("[data-behavior=toggle-with-navigation]").fadeOut()
    # $("[data-behavior=toggle-inline-with-navigation]").fadeOut()
    $("[data-behavior=toggle-inline-with-navigation]").css("display", "none")
  
  false
)

# Title edit form
$(document).on("mouseenter", "[data-behavior=edit-title]", (e) ->
  $header = $("[data-behavior=edit-title]").find("h1")
  $form = $("[data-behavior=edit-title]").find("form")
  
  if $("[data-behavior=navigation]").is(":visible")
    $header.hide()
    $form.show()
)

$(document).on("mouseleave", "[data-behavior=edit-title]", (e) ->
  $header = $("[data-behavior=edit-title]").find("h1")
  $form = $("[data-behavior=edit-title]").find("form")
  
  if !$form.find("input").is(":focus")
    $header.show()
    $form.hide()
)

$(document).on("blur", "[data-behavior=edit-title] input", (e) ->
  $("[data-behavior=edit-title]").trigger("mouseleave")
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
