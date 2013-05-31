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

# Sidebar
$(document).on("mouseenter", "[data-behavior=organization-sidebar]", (e) ->
  $this = $(this)
  $this.animate(height: $("[data-behavior=container]").outerHeight())
)

$(document).on("mouseleave", "[data-behavior=organization-sidebar]", (e) ->
  $this = $(this)
  $this.animate(height: $this.css("minHeight"))
)
