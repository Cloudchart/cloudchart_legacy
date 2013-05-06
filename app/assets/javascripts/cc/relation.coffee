root            = @
@cc            ?= {}
scope           = @cc


relation_counter    = 0


class Relation extends cc.Model
    
    @default_type: 'tree',
    
    @known_attributes: ['id', 'parent_id', 'child_id', 'type', 'weak'],
    
    constructor: (@chart, attributes = {}) ->
        if arguments.length == 1
            attributes  = @chart
            @chart      = undefined

        super attributes
        
        @attributes['id']      ?= "_#{++relation_counter}"
        @attributes['type']    ?= Relation.default_type
        @attributes['weak']    ?= false


$.extend scope,
    Relation:   Relation
