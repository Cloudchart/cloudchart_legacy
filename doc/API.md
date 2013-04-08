# CloudChart 2.0ß API

**Todo**

- Proper nodes editing
	- [x] More helper methods for tree purpose
	- [x] Rename left, right to parent, child
	- [ ] Store type + entity_id in Identity instead of person_id
- Controller actions
	- [x] Return information for subtree: nodes, links, identities, persons
	- [x] Return ancestor_ids + append them to nodes
	- [ ] Save dumped data representing subtree
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
Node.find(…).create_nested_node({ title: "Node title" }, { type: "direct" })
```

Remove parent from node:

```ruby
Node.find(…).remove_parent
```

Remove old parent and ensure new:

```ruby
Node.find(…).ensure_parent(Node.find(...), { type: "direct" })
```


## JSON API

### Nodes

**Description**

Provides access to nodes and their subtrees.

#### Index

**Description**

Returns a list of chart-type nodes for user.

**Sample Queries**

```
curl -X GET http://cloudchart.dev/nodes.json
```

**Sample Response**

```json
[
    {
		created_at: "2013-04-02T11:16:04Z",
		title: "Chart Name",
		type: "chart",
		updated_at: "2013-04-02T11:16:04Z",
		id: "515abdf44660f3d5fc000002",
		level: 0
	}
]
```

#### Show

**Description**

Returns a subtree information for specific node. Includes:

- root_id: current node id
- ancestor_ids: array of ancestor ids
- nodes: ancestor, root, descendant nodes (unique)
- links: root and descendant links
- identities: list of all descendant identities
- persons: list of all persons linked to identities

**Sample Queries**

```
curl -X GET http://cloudchart.dev/nodes/515abdf44660f3d5fc000002.json
```

**Sample Response**

```json
{
	root_id: "515abdf44660f3d5fc000002",
	ancestor_ids: [ ],
	nodes: [
		{
			created_at: "2013-04-02T11:16:04Z",
			title: "Chart Name",
			type: "chart",
			updated_at: "2013-04-02T11:16:04Z",
			id: "515abdf44660f3d5fc000002",
			level: 0
		},
		{
			created_at: "2013-04-08T10:01:07Z",
			title: "Chart Node",
			type: null,
			updated_at: "2013-04-08T10:01:07Z",
			id: "516295634660f3bad5000001",
			level: 1
		}
	],
	links: [
		{
			child_node_id: "515abdf44660f3d5fc000002",
			parent_node_id: "516295634660f3bad5000001",
			type: "direct",
			id: "516295634660f3bad5000002"
		}
	],
	identities: [
		{
			node_id: "515abdf44660f3d5fc000002",
			person_id: "5162964a4660f3bad5000003",
			position: null,
			type: "employee",
			id: "5162965d4660f3bad5000004"
		}
	],
	persons: [
		{
			description: null,
			external_id: "1",
			first_name: "Daria",
			headline: null,
			last_name: "Nifontova",
			note: null,
			profile_url: null,
			type: null,
			user_id: null,
			id: "5162964a4660f3bad5000003",
			identifier: "Daria Nifontova(ln:1)",
			name: "Daria Nifontova",
			picture: "/images/ico-person.png",
			position: null,
			company: null
		}
	]
}
```
