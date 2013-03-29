# CloudChart 2.0ß database schema

**Todo**

- Proper Link model for quick representation?
- Timeline support for chart?
- Additional attributes?

**Workarounds**

- Root nodes: Chart.find(...).nodes.where(right_links_ids: [])

---

## User

- **Embeds many** authorizations
- **Has many** accesses
- name [String]
- email [String]
- …

## Authorization

- **Embedded in** user
- provider [Enum: Linkedin, Facebook, …]
- uid [String]
- token [String]
- secret [String]
- …

## Access

- **Belongs to** user
- **Belongs to** organization
- level [Enum: public, token, owner]
- …

## Organization

- **Has many** accesses
- **Has many** persons
- **Has many** charts
- title [String]
- token [String]
- …

## Person

- **Belongs to** organization
- **Has many** identities
- provider [Enum: Linkedin, Facebook, …]
- external_id [String]
- first_name [String]
- last_name [String]
- picture [File]
- …

## Chart

- **Belongs to** organization
- **Has many** nodes
- **Has many** links
- type [Enum: structure, projects, project]
- started_at [Date]
- finished_at [Date]
- …

## Node

- **Belongs to** chart
- **Has many** identities
- **Has and belongs to many** left_links (class: Link)
- **Has and belongs to many** right_links (class: Link)
- title [String]
- position [Int, Int]
- …

## Link

- **Belongs to** chart
- **Belongs to** left_node (class: Node)
- **Belongs to** right_node (class: Node)
- connection_type [?]
- attributes [?]
- …

## Identity

- **Belongs to** node
- **Belongs to** person
- type [Enum: employee, freelancer, vacancy]
- position [String]
- department [String]
- …
