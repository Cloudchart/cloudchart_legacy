root        = @
@cc        ?= {}
scope       = @cc


node_counter    = 0
default_type    = 'node'


class Node extends cc.Model
    
    @known_attributes: ['id', 'type', 'title'],
    

    constructor: (@chart, attributes = {}) ->
        if arguments.length == 1
            attributes  = @chart
            @chart      = undefined

        super attributes

        @attributes['id']      ?= "_#{++node_counter}"
        @attributes['type']    ?= default_type
        @attributes['title']   ?= ''


    relations: (type) ->
        return unless @chart?

        @chart.relations.filter((relation) => relation.type() == cc.Relation.default_type and relation["#{type}_id"].apply(relation) == @id())


    children: ->
        return unless @chart?

        @relations('parent').map((relation) => @chart.nodes_map[relation.child_id()])
    

    descendants: ->
        return unless @chart?

        children = @children()

        children.reduce ((memo, child) -> memo.push child.descendants()... ; memo), children


    parent: ->
        return unless @chart?

        @relations('child').map((relation) => @chart.nodes_map[relation.parent_id()])[0]
    

    parents: ->
        return unless @chart?

        parents = []

        if parent = @parent()
            parents.unshift parent
            parents.unshift parent.parents()...

        parents


$.extend scope,
    Node:   Node
