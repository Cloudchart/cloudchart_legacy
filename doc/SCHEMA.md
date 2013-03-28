# CloudChart 2.0ß database schema

---

**Todo**

- Proper Link model for quick representation?
- Person-Node relationship as separate model with attributes?
- Timeline support for chart?
- Additional attributes?

---

## User

- **Embeds many** authorizations
- name [String]
- email [String]
- …

## Authorization

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

- **Has many** charts
- title [String]
- token [String]
- …

## Person

- **Belongs to** organization
- **Has and belongs to many** nodes
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
- **Has and belongs to many** persons
- title [String]
- …

## Link

- **Belongs to** chart
- **Belongs to** left_node (class: Node)
- **Belongs to** right_node (class: Node)
- connection_type [?]
- attributes [?]
- …

