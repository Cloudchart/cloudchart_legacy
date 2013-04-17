//= require core_ext
//= require jquery
//= require jquery_ujs
//= require handlebars
//= require plugins
//= require cc
//= require_tree ./templates

$ ->
  # Init PersonsView
  container = $("[data-behavior=persons-view]")
  if container.length == 1
    container.data("personsView", new cc.PersonsView(
      container: container
    ))