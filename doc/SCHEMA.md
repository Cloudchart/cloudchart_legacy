# CloudChart 2.0ß database schema

**Todo**

- Timeline support for chart?

**Workarounds**

```rspec spec/prototypes/organizations_spec.rb```

**Persons**

- ФИО (латиница, на родном языке) (**fb?**)
- Национальность (**fb?**)
- Визы (**fb?**)
- Гражданство (**fb?**)
- День рождения
- Пол
- Места (рождения, текущее)
- Образования (какое, даты и т.п.)
- Работа: компании, должности, зарплаты, проекты
- Скиллы (**fb?**)
- Биография
- Контактная информация (**fb?**)
- Соцсети (**fb?**)
- Готов переехать (**fb?**)
- Семейный статус
- Семья
- Картинка

## User

- **Embeds many** authorizations
- **Has many** accesses
- **Has many** persons
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
- **Has many** nodes
- **Has many** links
- title [String]
- token [String]
- …

## Person

- **Belongs to** organization
- **Belongs to** user
- **Has many** identities
- type [Enum: Linkedin, Facebook, …]
- external_id [String]
- profile_url [String]
- picture_url [String]
- first_name [String]
- last_name [String]
- birthday [Date]
- gender [Enum: male, female]
- hometown [String]
- location [String]
- education [Array[Hash[...]]]
- work [Array[Hash[...]]]
- description [String]
- status [String]
- family [Array[Hash[name,id,relationship]]]

## Node

- **Belongs to** organization
- **Has many** identities
- **Has and belongs to many** parents (class: Node)
- **Has and belongs to many** parent_links (class: Link)
- **Has and belongs to many** child_links (class: Link)
- type [Enum: chart, node (nil), imaginary, structure?, projects?, project?]
- title [String]
- position [Int, Int]
- started_at [Date]
- finished_at [Date]
- …

## Link

- **Belongs to** parent_node (class: Node)
- **Belongs to** child_node (class: Node)
- type: [Enum: direct, indirect]
- …

## Identity

- **Belongs to** node
- type [Enum: employee, freelancer, vacancy]
- entity_id [ObjectId: person_id, ...]
- title [String]
- position [String]
- …
