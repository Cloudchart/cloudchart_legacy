# CloudChart 2.0ß API

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

Includes nested **nodes** and **identities**.

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
			position: 0,
			type: "direct",
			updated_at: "2013-04-08T10:01:07Z",
			id: "516295634660f3bad5000002"
		}
	],
	identities: [
		{
			entity_id: "5162d8f84660f37731000005",
			node_id: "5162bc9e4660f37731000003",
			type: "employee",
			id: "5162d9154660f37731000006",
			entity: {
				/* Person attributes */
			}
		},
		{
			entity_id: "5162d8f84660f37731000006",
			node_id: "5162bc9e4660f37731000003",
			type: "vacancy",
			id: "5162da904660f37731000007",
			entity: {
				/* Vacancy attributes */
			}
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

Returns a list of stored persons for organization.

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

### Vacancies

#### Search

**Description**

Returns a vacancy search results.

**Parameters**

- ```search[query]``` — [String] Search query

**Sample Queries**

```
curl -X GET http://cloudchart.dev/organizations/{id}/vacancies/search.json?q=Anton
```

**Sample Response**

```json
{
	vacancies: [
		{
			created_at: "2013-06-25T14:50:39Z",
			organization_id: "51ac74944660f31b0700000a",
			title: "Test",
			updated_at: "2013-06-25T14:50:39Z",
			id: "51c9ae3f4660f3e1e4000006",
			name: "Vacancy: Test"
		}
	]
}
```
