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
	- [x] Save dumped data representing subtree
		- [x] Ability to update nodes
		- [x] Ability to update links
		- [x] Generate ObjectId for new elements — /^_[0-9]+$/
		- [x] Tree validation
			- [x] Rights
			- [x] Multiple child_ids
	- [x] Imaginary links support (as a boolean flag)
		- [?] Destroy imaginary links when adding real ones
		- [x] Check all nodes has only one link
	- [ ] Implement cancan abilities
		- [ ] Implement nodes access properly
		- [ ] Add test cases for unauthorized users etc
	- [ ] Atomic update actions on nodes
	- [ ] Timeline support
- Persons controller
	- [x] Sign in with Linkedin/Facebook
	- [x] Search people using Linkedin/Facebook
	- [x] Add people to database and search using Elasticsearch
	- [x] Rename persons client namespace, move initializer to PersonsView, bind 	events globally
	- [ ] Autocomplete
		- [x] Fix loading when text is changing
		- [x] Improve parallel loading
		- [x] Fix animation when dragging
		- [x] Show dropped people at the bottom of chart
		- [x] Remove dropped person from the bottom of chart
		- [x] Unstar to remove
		- [x] Improve animation
		- [?] Show results when backspacing search term
	- [x] Save user connections to our database
	- [ ] Allow users to edit profile
		- [x] Store tokens (access types) in separate collection
		- [x] Implement ability to create person token
		- [ ] Implement edit form
		- [ ] Allow user to add multiple emails
		- [ ] Allow user to connect social profiles
	- [ ] Merge people from different sources
	- [ ] Natural language search
	- [ ] Multiple selection and drag-n-drop
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

### Organizations

Includes nested **nodes** and **persons**.

### Nodes

**Description**

Provides access to nodes and their subtrees.

#### Index

**Description**

Returns a list of chart-type nodes for user.

**Sample Queries**

```
curl -X GET http://cloudchart.dev/organizations/{id}/nodes.json
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
curl -X GET http://cloudchart.dev/organizations/{id}/nodes/515abdf44660f3d5fc000002.json
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
			created_at: "2013-04-08T10:01:07Z",
			is_imaginary: false,
			parent_node_id: "516295634660f3bad5000001",
			type: "direct",
			updated_at: "2013-04-08T10:01:07Z",
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
				/* Person attributes */
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
curl -X PUT http://cloudchart.dev/organizations/{id}/nodes/515abdf44660f3d5fc000002.json
```

**Sample Response**

HTTP status: {200, 422}

```json
{
	errors: [
		"Node is invalid",
		"Link is invalid"
	]
}
```

### Persons

#### Index

**Description**

Returns a list of stored persons for user.

**Sample Queries**

```
curl -X GET http://cloudchart.dev/organizations/{id}/persons.json
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

- ```search[query]``` — [String] Search query
- ```search[provider]``` — [String] "Local" or API name

**Sample Queries**

```
curl -X GET http://cloudchart.dev/organizations/{id}/persons/search.json?q=Anton
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
