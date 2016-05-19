# ActiveRecordLite
ActiveRecordLite is an object-relational mapping system inspired by
ActiveRecord. Uses Ruby's metaprogramming capabilities to implement its
core functionality.

## Current Features
- `SQLObject::find(id)` returns a SQLObject with attributes matching the database row having the corresponding id
- `SQLObject#insert` creates new row in the database with the SQLObject's attributes and assigns an id
- `SQLObject#update` maps current attribute values over previous column values in the database on the row with the corresponding id
- `SQLObject#save` inserts or updates SQLObject based on `id.nil?`
- `SQLObject#where(params)` forms and executes SQL query based on params; returns an array of SQLObjects
- `SQLObject#belongs_to(name, options)` defines a method, `name`, that returns a SQLObject whose `#model_name` and `:primary_key` value correspond to the `:class_name` option and `:foreign_key` value of the association
- `SQLObject#has_many(name, options)` is the inverse of `#belongs_to`; defines a method, `name` that returns an array of SQLObjects with appropriate `#model_name`s and `:primary_key` values
- `SQLObject#has_one_through(name, through_name, source_name)` defines a relationship between two SQLObjects through two `#belongs_to` relationships. Defines a method, `name`, that returns a SQLObject whose `#model_name` corresponds to the `source_name`

## Using ActiveRecordLite
- Add this repo to your project
- Require `'active_record_lite'`

Example:

```ruby
require './ActiveRecordLite/active_record_lite'
DBConnection.open('trees.db')

class Tree < SQLObject
  belongs_to :family
  has_one_through :type, :family, :type

  finalize!
end

class Family < SQLObject
  has_many :trees
  belongs_to :type

  finalize!
end

class Type < SQLObject
  has_many :families

  finalize!
end

type = Type.new(name: "Confier")
type.save

family = Family.new(name: "Cypress", type_id: type.id)
family.save

tree = Tree.new(name: "Dawn Redwood", family_id: family.id)
tree.save

Tree.where(name: "Dawn Redwood") # => [#<Tree:0x007ffc642ec080 @attributes={:id=>1, :name=>"Dawn Redwood", :family_id=>1}>]
Tree.where(name: "Dawn Redwood").first.family # => #<Family:0x007ffc641ff140 @attributes={:id=>1, :name=>"Cypress", :type_id=>1}>
Tree.where(name: "Dawn Redwood").first.type # => #<Type:0x007ffc64088fa0 @attributes={:id=>1, :name=>"Confier"}>
```

## To Do
- [ ] Write `has_many_through`
- [ ] Write `includes` to prefetch data
- [ ] Write `joins`
