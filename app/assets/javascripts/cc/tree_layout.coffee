root        = @
@cc        ?= {}
scope       = @cc


distance    = (wm, wp) ->
    wm.width / 2 + wp.width / 2 + 50 + if wm.parent == wp.parent then 10 else 20


first_walk = (v) ->
    if v.children?.length > 0

        default_ancestor = v.children[0]

        for w in v.children
            first_walk(w)
            apportion(w, default_ancestor)
        
        execute_shifts(v)
        
        midpoint = .5 * (v.children[0].__tree.prelim + v.children[v.children.length - 1].__tree.prelim)
        
        if v.__tree.left_sibling?
            v.__tree.prelim = v.__tree.left_sibling.__tree.prelim + distance(v, v.__tree.left_sibling)
            v.__tree.mod = v.__tree.prelim - midpoint
        else
            v.__tree.prelim = midpoint

    else
        if v.__tree.left_sibling?
            v.__tree.prelim = v.__tree.left_sibling.__tree.prelim + distance(v, v.__tree.left_sibling)


second_walk = (v, m) ->
    v.x = v.__tree.prelim + m
    v.y = v.__tree.level
    for w in v.children ? []
        second_walk(w, m + v.__tree.mod)


apportion = (v, default_ancestor) ->
    if v.__tree.left_sibling?
        vip = v
        vop = v
        vim = v.__tree.left_sibling
        vom = vip.__tree.leftmost_sibling
        
        sip = vip.__tree.mod
        sop = vop.__tree.mod
        sim = vim.__tree.mod
        som = vom.__tree.mod
        
        while next_right(vim)? and next_left(vip)?
            vim = next_right(vim)
            vip = next_left(vip)
            vom = next_left(vom)
            vop = next_right(vop)
            
            v.__tree.ancestor = vop
            
            shift = (vim.__tree.prelim + sim) - (vip.__tree.prelim + sip) + distance(vim, vip)
            
            if shift > 0
                move_subtree(ancestor(vim, v, default_ancestor), v, shift)
                sip = sip + shift
                sop = sop + shift
            
            sim = sim + vim.__tree.mod
            sip = sip + vip.__tree.mod
            som = som + vom.__tree.mod
            sop = sop + vop.__tree.mod
        
        if next_right(vim)? and !next_right(vop)?
            vop.__tree.thread   = next_right(vim)
            vop.__tree.mod     += sim - sop
        
        if next_left(vip)? and !next_left(vom)?
            vom.__tree.thread   = next_left(vip)
            vom.__tree.mod     += sip - som
            default_ancestor    = v
    
    default_ancestor



next_left = (v) ->
    v.children?[0] ? v.__tree.thread


next_right = (v) ->
    v.children?[v.children.length - 1] ? v.__tree.thread


move_subtree = (wm, wp, shift) ->
    subtrees = wp.__tree.index - wm.__tree.index
    wm.__tree.change += shift / subtrees
    wp.__tree.change -= shift / subtrees
    wp.__tree.prelim += shift
    wp.__tree.shift += shift
    wp.__tree.mod += shift


ancestor = (vim, v, default_ancestor) ->
    if vim.__tree.ancestor.parent == v.parent then vim.__tree.ancestor else default_ancestor


execute_shifts = (v) ->
    shift   = 0
    change  = 0
    
    for w in v.children.slice(0).reverse()
        w.__tree.prelim += + shift
        w.__tree.mod += shift
        change  = change + w.__tree.change
        shift   = shift + w.__tree.shift + change

# walk over tree, executing callback

traverse_with_callback = (node, callback, level = 0) ->
    node.children.forEach((child, i, children) -> traverse_with_callback(child, callback, level + 1)) if node.children?
    callback node, level



# layout

layout = (root, options = {}) ->

    width   = 0
    height  = 0

    traverse_with_callback root, (v, level) ->
        
        # test calculations
        
        v.height    = Math.round(Math.random() * 5) + 2
        v.width     = Math.round(Math.random() * 10) * 5 + 20
        
        # / test calculations

        v.__tree =
            change:             0
            prelim:             0
            shift:              0
            mod:                0
            thread:             null
            level:              level
            ancestor:           v
            index:              v.parent?.children.indexOf(v) ? 0
            left_sibling:       v.parent?.children[v.parent?.children.indexOf(v) - 1]
            leftmost_sibling:   v.parent?.children[0]
        
    first_walk(root)
    second_walk(root, -root.__tree.prelim)
        

    traverse_with_callback root, (v) ->
        delete v.__tree


    root



$.extend scope,
    tree_layout: layout


###
tree =
    title: 'root',
    children: [
        {
            title: 'a'
            children: [
                {
                    title: 'h'
                }, {
                    title: 'i'
                }, {
                    title: 'j'
                }, {
                    title: 'k'
                }, {
                    title: 'l'
                }, {
                    title: 'm'
                }, {
                    title: 'n'
                    children: [
                        {
                            title: 'q'
                        }
                    ]
                }
            ]
        }, {
            title: 'b'
        }, {
            title: 'c'
        }, {
            title: 'd'
            children: [
                {
                    title: 'o'
                }
            ]
        }, {
            title: 'e'
        }, {
            title: 'f'
            children: [
                {
                    title: 'p'
                    children: [
                        {
                            title: 'r'
                        }, {
                            title: 's'
                        }, {
                            title: 't'
                        }, {
                            title: 'u'
                        }, {
                            title: 'v'
                        }, {
                            title: 'w'
                        }, {
                            title: 'x'
                        }
                    ]
                }
            ]
        }
    ]



tree.children[0].parent = tree
tree.children[1].parent = tree
tree.children[2].parent = tree
tree.children[3].parent = tree
tree.children[4].parent = tree
tree.children[5].parent = tree

tree.children[0].children[0].parent = tree.children[0]
tree.children[0].children[1].parent = tree.children[0]
tree.children[0].children[2].parent = tree.children[0]
tree.children[0].children[3].parent = tree.children[0]
tree.children[0].children[4].parent = tree.children[0]
tree.children[0].children[5].parent = tree.children[0]
tree.children[0].children[6].parent = tree.children[0]

tree.children[3].children[0].parent = tree.children[3]

tree.children[5].children[0].parent = tree.children[5]

tree.children[0].children[6].children[0].parent = tree.children[0].children[6]

tree.children[5].children[0].children[0].parent = tree.children[5].children[0]
tree.children[5].children[0].children[1].parent = tree.children[5].children[0]
tree.children[5].children[0].children[2].parent = tree.children[5].children[0]
tree.children[5].children[0].children[3].parent = tree.children[5].children[0]
tree.children[5].children[0].children[4].parent = tree.children[5].children[0]
tree.children[5].children[0].children[5].parent = tree.children[5].children[0]
tree.children[5].children[0].children[6].parent = tree.children[5].children[0]
###
    
tree = {
    title: 'r'
    children: [
        {
            title: 'a'
            children: [
                {
                    title: 'd'
                }, {
                    title: 'e'
                }, {
                    title: 'f'
                    children: [
                        {
                            title: 'i'
                        }, {
                            title: 'j'
                        }
                    ]
                }, {
                    title: 'f\''
                }
            ]
        }, {
            title: 'b'
            children: [
                {
                    title: 'g'
                }, {
                    title: 'h'
                    children: [
                        {
                            title: 'k'
                        }, {
                            title: 'l'
                        }, {
                            title: 'm'
                        }, {
                            title: 'n'
                        }, {
                            title: 'o'
                        }
                    ]
                }
            ]
        }, {
            title: 'c'
        }
    ]
}

tree.children[0].parent = tree
tree.children[1].parent = tree
tree.children[2].parent = tree

tree.children[0].children[0].parent = tree.children[0]
tree.children[0].children[1].parent = tree.children[0]
tree.children[0].children[2].parent = tree.children[0]
tree.children[0].children[3].parent = tree.children[0]


tree.children[1].children[0].parent = tree.children[1]
tree.children[1].children[1].parent = tree.children[1]

tree.children[0].children[2].children[0].parent = tree.children[0].children[2]
tree.children[0].children[2].children[1].parent = tree.children[0].children[2]

tree.children[1].children[1].children[0].parent = tree.children[1].children[1]
tree.children[1].children[1].children[1].parent = tree.children[1].children[1]
tree.children[1].children[1].children[2].parent = tree.children[1].children[1]
tree.children[1].children[1].children[3].parent = tree.children[1].children[1]
tree.children[1].children[1].children[4].parent = tree.children[1].children[1]

    
$.extend scope,
    test_tree_layout: layout(tree)
