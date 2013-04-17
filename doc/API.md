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
		- [x] Ability to update links
		- [x] Generate ObjectId for new elements — /^_[0-9]+$/
		- [ ] Tree validation (cyclic links, multiple child_ids)
	- [ ] Atomic update actions on nodes
- Persons controller
	- [x] Sign in with Linkedin/Facebook
	- [x] Search people using Linkedin/Facebook
	- [x] Add people to database and search using Elasticsearch
- Ability to select/group nodes?
- Data mapping layer?

## Internal API

### Nodes

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

### Persons

#### Index

**Description**

Returns a list of stored persons for user.

**Sample Queries**

```
curl -X GET http://cloudchart.dev/persons.json
```

**Sample Response**

```json
{
	persons: [
	    {
			description: null,
			external_id: "1",
			first_name: "Daria",
			headline: null,
			last_name: "Nifontova",
			note: null,
			organization_id: null,
			profile_url: null,
			type: null,
			user_id: null,
			id: "5162d8f84660f37731000005",
			identifier: "Daria Nifontova(:1)",
			name: "Daria Nifontova",
			picture: "/images/ico-person.png",
			position: null,
			company: null
		}
	]
}
```
		
#### Search

**Description**

Returns a person search results.

**Parameters**

- ```search[q]``` — [String] Search query
- ```search[local]``` — [Boolean] Include local search results

**Sample Queries**

```
curl -X GET http://cloudchart.dev/persons/search.json?q=Anton
```

**Sample Response**

```json
{
	persons: [
	    {
			description: null,
			external_id: "1",
			first_name: "Daria",
			headline: null,
			last_name: "Nifontova",
			note: null,
			organization_id: null,
			profile_url: null,
			type: null,
			user_id: null,
			id: "5162d8f84660f37731000005",
			identifier: "Daria Nifontova(:1)",
			name: "Daria Nifontova",
			picture: "/images/ico-person.png",
			position: null,
			company: null
		},
		{
			description: "I work as a copywriter and intern as a UI/UX designer.",
			external_id: "f4DADgy_LV",
			first_name: "Daria",
			headline: "Copywriter at DigDog",
			last_name: "Nifontova",
			note: null,
			organization_id: null,
			profile_url: "http://www.linkedin.com/profile/view?id=123922870&authType=OUT_OF_NETWORK&authToken=sCsQ&trk=api*a221124*s229092*",
			type: "ln",
			user_id: null,
			id: "516879c8591db4a1fc00003c",
			identifier: "Daria Nifontova(ln:f4DADgy_LV)",
			name: "Daria Nifontova",
			picture: "http://m3.licdn.com/mpr/mprx/0_xgY8aXzn4RFiXGboZOymwLRn0sWTXTwoZDhDH5XZNOHGi8JkVS0uEfHbUEy",
			position: "Copywriter",
			company: "DigDog"
		},
		{
			description: null,
			external_id: "1631228798",
			first_name: "Daria",
			headline: null,
			last_name: "Nifontova",
			note: null,
			organization_id: null,
			profile_url: "http://www.facebook.com/daria.nifontova",
			type: "fb",
			user_id: null,
			id: "516879fb591db4a1fc000060",
			identifier: "Daria Nifontova(fb:1631228798)",
			name: "Daria Nifontova",
			picture: "https://fbcdn-profile-a.akamaihd.net/hprofile-ak-ash3/573204_1631228798_775146040_q.jpg",
			position: null,
			company: null
		}
	]
}
```
