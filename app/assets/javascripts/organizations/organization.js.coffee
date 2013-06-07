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

$ ->
  # Sticky sidebar
  $sidebar = $("[data-behavior=organization-sidebar]")
  $sidebar.sticky(topSpacing: 20)
  $sidebar.css(width: $sidebar.outerWidth())

$(document).on("mouseenter", "[data-behavior=organization-sidebar]", (e) ->
  $this = $(this)
  $this.find(".contents").stop().slideDown()
)

$(document).on("mouseleave", "[data-behavior=organization-sidebar]", (e) ->
  $this = $(this)
  $this.find(".contents").stop().slideUp()
)
