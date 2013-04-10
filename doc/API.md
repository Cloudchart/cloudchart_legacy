# CloudChart 2.0ß API

**Todo**

- Proper nodes editing
	- [x] More helper methods for tree purpose
	- [x] Rename left, right to parent, child
	- [x] Store type + entity_id in Identity instead of person_id
	- [x] Imaginary nodes
- Nodes controller
	- [x] Return information for subtree: nodes, links, identities
	- [x] Return ancestor_ids + append them to nodes
	- [ ] Save dumped data representing subtree
		- [x] Ability to update nodes
		- [ ] Ability to update links
		- [ ] Generate ObjectId for new elements — /^_[0-9]+$/
		- [ ] Tree validation (cyclic links, multiple child_ids)
	- [ ] Atomic update actions on nodes
- Persons controller
- Ability to select/group nodes?
- Data mapping layer?

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
- identities: list of all descendant identities with embedded entities

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
			entity_id: "5162d8f84660f37731000005",
			node_id: "5162bc9e4660f37731000003",
			position: null,
			type: "employee",
			id: "5162d9154660f37731000006",
			entity: {
				description: null,
				external_id: "1",
				first_name: "Daria",
				headline: null,
				last_name: "Nifontova",
				note: null,
				profile_url: null,
				type: null,
				user_id: null,
				id: "5162d8f84660f37731000005",
				identifier: "Daria Nifontova(ln:1)",
				name: "Daria Nifontova",
				picture: "/images/ico-person.png",
				position: null,
				company: null
			}
		},
		{
			entity_id: null,
			node_id: "5162bc9e4660f37731000003",
			position: "Test",
			type: "vacancy",
			id: "5162da904660f37731000007",
			entity: null
		}
	]
}
```

#### Update

**Description**

Allows to update subtree structure. Requires full data dump, including:

- nodes
- links
- identities

**Sample Queries**

```
curl -X PUT http://cloudchart.dev/nodes/515abdf44660f3d5fc000002.json
```

**Sample Response**

Returns 200 or 422 with no content.
