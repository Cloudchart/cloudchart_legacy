# Navigation
$(document).on("click", "[data-behavior=toggle-navigation]", ->
  $("[data-behavior=navigation]").slideToggle()
  $("[data-behavior=navigation-overlay]").fadeToggle()
  false
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
