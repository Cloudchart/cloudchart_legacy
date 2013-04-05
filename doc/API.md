# CloudChart 2.0ß API

**Todo**

- Proper nodes editing
	- More helper methods for tree purpose
- Controller actions
	- Return information for subtree: nodes, links, identities
	- Save dumped data representing subtree
- Data mapping layer?

---

## Internal API

### Charts/nodes

Create chart:

```ruby
Organization.find(…).nodes.create_chart_node(title: "Node title")
```

Create nested node:

```ruby
Node.find(...).create_nested_node({ title: "Node title" }, { type: "direct" })
```

Remove parent from node:

```ruby
Node.find(...).remove_parent
```

Remove old parent and ensure new:

```ruby
Node.find(...).ensure_parent(Node.find(...), { type: "direct" })
```


## JSON API

### Coming soon
