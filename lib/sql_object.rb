require_relative 'db_connection'
require 'active_support/inflector'

class SQLObject
  extend Searchable
  include Searchable
  include Associatable
  extend Associatable

  def self.columns
    if @everything.nil?
      @everything = DBConnection.execute2(<<-SQL)
        SELECT
          *
          FROM
          #{self.table_name}
        SQL
      end

    @everything[0].map {|column| column.to_sym}
  end

  def self.finalize!
    columns.each do |column|

      define_method(column) do
        attributes[column]
      end

      define_method("#{column}=".to_sym) do |val|
        attributes[column] = val
      end
    end

  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name ||= "#{self}".tableize
  end

  def self.all
    all = DBConnection.execute(<<-SQL)
      SELECT
        *
        FROM
        #{self.table_name}
      SQL
      all

      self.parse_all(all)
  end

  def self.parse_all(results)
    results.map {|hash| self.new(hash)}
  end

  def self.find(id)
    num_id = id
    find = DBConnection.execute(<<-SQL, id)
      SELECT
        *
        FROM
        #{self.table_name}
        WHERE
        id = ?
      SQL

    return nil if find.empty?

    self.new(find[0])
  end

  def initialize(params = {})
    columns = self.class.columns
    params.each do |attr_name, val|
      attr_name = attr_name.to_sym
      raise "unknown attribute '#{attr_name}'" unless columns.include?(attr_name)

      self.send("#{attr_name}=", val)
    end
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    @attributes.values
  end

  def insert
    columns = self.class.columns.drop(1)
    col_names = columns.map(&:to_s).join(", ")
    question_marks = (['?'] * columns.count).join(', ')

    DBConnection.execute(<<-SQL, *attribute_values)
      INSERT INTO
      #{self.class.table_name} (#{col_names})
      VALUES
      (#{question_marks})
      SQL

      self.id = DBConnection.last_insert_row_id
  end

  def update
    columns = self.class.columns.map {|attr_name| "#{attr_name} = ?"}
    set_line = columns.join(', ')
      DBConnection.execute(<<-SQL, *attribute_values, self.id)
      UPDATE
      #{self.class.table_name}
      SET
      #{set_line}
      WHERE
      id = ?
    SQL
  end

  def save
    if self.id.nil?
      insert
    else update
    end
  end
end
