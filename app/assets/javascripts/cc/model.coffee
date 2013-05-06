root        = @
@cc        ?= {}
scope       = cc



class Model
    

    @known_attributes: [],
    

    @extend: (instance) ->
        @known_attributes.forEach (name) ->
            instance[name] = -> instance.attributes[name]
    

    constructor: (attributes = {}) ->
        known_attributes    = @constructor.known_attributes
        names               = Object.keys(attributes).filter (name) -> known_attributes.indexOf(name) >= 0
        @attributes         = names.reduce ((memo, name) -> memo[name] = attributes[name] ; memo), {}
        
        @constructor.extend(@)


$.extend scope,
    Model: Model
