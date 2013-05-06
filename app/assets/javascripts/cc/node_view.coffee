root        = @
@cc        ?= {}
scope       = @cc



widget = (node, options = {}) ->

    container = $(options.container) ; container = undefined if container.length == 0
    
    
    



$.extend scope,
    node_view: widget
    

# Node UJS event listeners


$(document).on 'click', '[data-node]', (event) ->
    event.stopPropagation()
    $('[data-node]').removeClass('active')
    $(@).addClass('active')


$(document).on 'click', (event) ->
    $('[data-node]').removeClass('active')


