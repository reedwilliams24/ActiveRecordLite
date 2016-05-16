require_relative 'db_connection'
require 'active_support/inflector'

require 'byebug'


# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns

    @columns ||= DBConnection.execute2(<<-SQL).first.map(&:to_sym)
      SELECT
        *
      FROM
        #{self.table_name}
    SQL

  end

  def self.finalize!
    self.columns.each do |attribute|
      ivar_name = "@#{attribute}"
      setter_equals = "#{attribute}="

      # Getter methods
      define_method(attribute.to_sym) do
        attributes[attribute.to_sym]
      end

      # Setter methods
      define_method(setter_equals.to_sym) do |value|
        attributes[attribute.to_sym] = value
      end
    end
  end

  def self.table_name=(table_name)
    table_name
  end

  def self.table_name
    "#{self.to_s.downcase}s"
  end

  def self.all
    query = DBConnection.execute(<<-SQL)
      SELECT
        #{self.table_name}.*
      FROM
        #{self.table_name}
    SQL
    parse_all(query)
  end

  def self.parse_all(results)
    results.map do |attributes|
      self.new(attributes)
    end
  end

  def self.find(id)
    query ||= DBConnection.execute(<<-SQL, id)
      SELECT
        #{self.table_name}.*
      FROM
        #{self.table_name}
      WHERE
        #{self.table_name}.id = ?
    SQL
    return nil if query.empty?
    self.new(query.first)
  end

  def initialize(params = {})
    params.each do |attr_name, value|

      columns = self.class.columns
      attr_sym = attr_name.to_sym

      raise "unknown attribute '#{attr_name}'" unless columns.include?(attr_sym)
      self.send("#{attr_name}=".to_sym, value)
    end

  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    self.class.columns.map {|col| send(col)}
    #attributes.each_value.map { |attribute| attribute }
  end

  def insert
    cols = self.class::columns
    col_names = cols.join(', ')

    question_marks = cols.map{"?"}.join(', ')

    #attr_vals = attribute_values

    DBConnection.execute(<<-SQL, *attribute_values)
      INSERT INTO
        #{self.class.table_name} (#{col_names})
      VALUES
        (#{question_marks})
    SQL

    self.id = DBConnection.last_insert_row_id
  end

  def update
    cols = self.class.columns.map{|col| "#{col} = ?"}.join(", ")

    DBConnection.execute(<<-SQL, *attribute_values, self.id)
      UPDATE
        #{self.class.table_name}
      SET
        #{cols}
      WHERE
        id = ?
    SQL
  end

  def save
    if self.id.nil?
      self.insert
    else
      self.update
    end
  end
end
