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

$(document).on("submit", "[data-behavior=edit-title] form", (e) ->
  $this = $(this)
  
  $.ajax(
    url: $this.attr("action"),
    type: $this.attr("method"),
    data: $this.serialize(),
    dataType: "json"
  ).done((result) ->
    $this.find("input[name$='[title]']").val(result.title)
    $this.closest("[data-behavior=edit-title]").find("[data-behavior=title]").html(result.title)
    $this.find("input[name$='[title]']").trigger("blur")
  )
  
  false
)

$ ->
  # Sticky sidebar
  $sidebar = $("[data-behavior=organization-sidebar]")
  $sidebar.sticky(topSpacing: 20)
  $sidebar.css(width: $sidebar.outerWidth())
  
  # Picture upload
  $file = $sidebar.find("[data-behavior=picture-upload]")
  $file.fileupload(
    type: "PUT"
    dataType: "json"
    formData: {}
    done: (e, data) ->
      $sidebar.find("[data-behavior=picture]").attr("src", data.result.preview_url)
  )

$(document).on("mouseenter", "[data-behavior=organization-sidebar]", (e) ->
  return if $(this).closest(".is-sticky").length == 0
  $(this).find("[data-behavior=sections]").slideDown(400)
)

$(document).on("mouseleave", "[data-behavior=organization-sidebar]", (e) ->
  return if $(this).closest(".is-sticky").length == 0
  $(this).find("[data-behavior=sections]").slideUp(400, ->
    $(this).css("display", "")
  )
)
