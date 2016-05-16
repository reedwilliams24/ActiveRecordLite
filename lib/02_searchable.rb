require_relative 'db_connection'
require_relative '01_sql_object'
require 'byebug'

module Searchable
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
end

class SQLObject
  include Searchable
  extend Searchable
  # def self.where(params)
  #
  # end

  # Mixin Searchable here...
end
