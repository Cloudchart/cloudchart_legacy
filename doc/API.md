# CloudChart 2.0ß API

**Todo**

- Proper nodes editing
- Controller actions for tree purposes
- Data mapping layer

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
