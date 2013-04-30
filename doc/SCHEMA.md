# CloudChart 2.0ß database schema

**Persons**

- ФИО (латиница, на родном языке) (**fb?, ln?**)
- Национальность (**fb?, ln?**)
- Визы (**fb?, ln?**)
- Гражданство (**fb?, ln?**)
- День рождения
- Пол (**ln?**)
- Места (рождения, текущее) (**ln?**)
- Образования (какое, даты и т.п.)
- Работа: компании, должности, зарплаты, проекты
- Скиллы (**fb?**)
- Биография
- Контактная информация (**fb?**)
- Соцсети (**fb?, ln?**)
- Готов переехать (**fb?, ln?**)
- Семейный статус (**ln?**)
- Семья (**ln?**)
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
- **Has many** nodes
- **Has many** links
- **Has many** identities
- title [String]
- token [String]
- …

## Person

- **Belongs to** user
- ? **Has many** identities
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
- education [Array[Hash[name,type?,degree?,concentration?,start_year?,end_year?]]]
- work [Array[Hash[employer(id?,name),position,description?,start_date?,end_date?]]]
- skills [Array[String]]
- description [String]
- phones [Array[Hash[type, number]]]
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

- **Belongs to** organization
- **Belongs to** node
- type [Enum: person, employee, freelancer, vacancy]
- entity_id [ObjectId: Person#id, ...]
- title [String]
- position [String]
- …
