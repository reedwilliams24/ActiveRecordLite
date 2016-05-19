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

### Where
```ruby
def where(params)

  where_string = params.map{|key, _| "#{key} = ?"}.join(" AND ")

  query = DBConnection.execute(<<-SQL, *params.values)
    SELECT
      #{self.table_name}.*
    FROM
      #{self.table_name}
    WHERE
      #{where_string}
  SQL

  query.map{|attrs| self.new(attrs)}

end
```

### Belongs To
```ruby
class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
      @primary_key = options[:primary_key] || :id
      @foreign_key = options[:foreign_key] || (name.to_s+"_id").to_sym
      @class_name = options[:class_name] || name.to_s.camelcase
  end
end


def belongs_to(name, options = {})
  self.assoc_options[name] = BelongsToOptions.new(name, options)

  define_method(name) do
    options = self.class.assoc_options[name]

    key_val = self.send(options.foreign_key)
    options
      .model_class
      .where(options.primary_key => key_val)
      .first
  end
end
```

### Has Many
```ruby
class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    @primary_key = options[:primary_key] || :id
    @foreign_key = options[:foreign_key] || (self_class_name.downcase+"_id").to_sym
    @class_name = options[:class_name] || name.to_s.camelcase.singularize
  end
end

def has_many(name, options = {})
  self.assoc_options[name] =
    HasManyOptions.new(name, self.name, options)

  define_method(name) do
    options = self.class.assoc_options[name]

    key_val = self.send(options.primary_key)
    options
      .model_class
      .where(options.foreign_key => key_val)
  end
end
```

### Has One Through
```ruby
def has_one_through(name, through_name, source_name)
  define_method(name) do
    through_options = self.class.assoc_options[through_name]
    source_options =
      through_options.model_class.assoc_options[source_name]

    through_table = through_options.table_name
    through_pk = through_options.primary_key
    through_fk = through_options.foreign_key

    source_table = source_options.table_name
    source_pk = source_options.primary_key
    source_fk = source_options.foreign_key

    key_val = self.send(through_fk)
    results = DBConnection.execute(<<-SQL, key_val)
      SELECT
        #{source_table}.*
      FROM
        #{through_table}
      JOIN
        #{source_table}
      ON
        #{through_table}.#{source_fk} = #{source_table}.#{source_pk}
      WHERE
        #{through_table}.#{through_pk} = ?
    SQL

    source_options.model_class.parse_all(results).first
  end
end
```
