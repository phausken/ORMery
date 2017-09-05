require_relative 'db_connection'
require_relative 'sql_object'

module Searchable
  def where(params)
    wheres = params.map {|k, v| "#{k} = ?"}
    where_line = wheres.join(' AND ')
    vals = params.values


    result = DBConnection.execute(<<-SQL, vals)
      SELECT
        *
        FROM
        #{self.table_name}
        WHERE
        #{where_line}
      SQL

    parse_all(result)
  end
end

class SQLObject
  extend Searchable
  include Searchable
end
