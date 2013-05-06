root        = @
@cc        ?= {}
scope       = @cc


$           = jQuery


class Chart extends cc.Model
    

    constructor: (attributes = {}) ->
        super attributes

        @nodes          = []
        @nodes_map      = {}
        @relations      = []
        @relations_map  = {}

        @root = new cc.Node @,
            title:  attributes.title
            type:   'chart'
        
        @add_node @root


    add_node: (node) ->
        
        # check if new node is of type chart and chart node already exists
        return console.error("Node of type 'chart' already exists") if node.type() == 'chart' and @nodes.filter((node) -> node.type() == 'chart').length > 0
        
        # check if node with the same id already exists
        return console.error("Node with id '#{node.id()}' already exists") if @nodes_map[node.id()]?
        
        node.chart = @
        
        @nodes.push node
        @nodes_map[node.id()] = node
    

    add_relation: (relation) ->
        
        # check if node with relation parent_id exists
        return console.error("Node with id '#{relation.parent_id()}' doesn't exists") unless @nodes_map[relation.parent_id()]?
        
        # check if node with relation child_id exists
        return console.error("Node with id '#{relation.child_id()}' doesn't exists") unless @nodes_map[relation.child_id()]?
        
        # check if relation with same type, parent_id and child_id already exists
        return console.error("Relation of type '#{relation.type()}' from '#{relation.parent_id()}' to '#{relation.child_id()}' already exists") if @relations.filter((r) -> r.type() == relation.type() and r.parent_id() == relation.parent_id() and r.child_id() == relation.child_id()).length > 0
        
        relation.chart = @
        
        @relations.push relation
        @relations_map[relation.id()] = relation


    validate: ->
        
        # find nodes not having default relation to parent
        nodes = @nodes.filter((node) => node.type() != 'chart' and @relations.filter((relation) -> relation.type() == cc.Relation.default_type and relation.child_id() == node.id()).length != 1)

        # link those nodes to root node
        nodes.forEach (node) =>
            @add_relation new cc.Relation({
                parent_id:  @root.id()
                child_id:   node.id()
                weak:       true
            })
        
        #
        
            

$.extend scope,
    Chart:  Chart
