# CloudChart 2.0ß API

## Internal API

### Charts/nodes

Create chart:

```
Organization.find(…).nodes.create_chart_node(title: "Node title")
```

Create nested node:

```
Node.find(...).create_nested_node({ title: "Node title" }, { type: "direct" })
```

## JSON API

