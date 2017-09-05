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

class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    @class_name.constantize
  end

  def table_name
    model_class.table_name
  end
end


class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    default_values =
      {:class_name => name.to_s.camelcase,
      :primary_key => :id,
      :foreign_key => "#{name}_id".to_sym}

      values = default_values.merge(options)


      values.each do |k, v|
        self.instance_variable_set("@#{k}", v)
      end
    end
end

class HasManyOptions < AssocOptions
  def initialize(name, class_name, options = {})
    default_values =
      {:foreign_key => "#{class_name.underscore}_id".to_sym,
      :primary_key => :id,
      :class_name => name.to_s.singularize.camelcase
    }

      values = default_values.merge(options)

      values.each do |k, v|
        self.instance_variable_set("@#{k}", v)
      end

  end
end


module Associatable
  def belongs_to(name, options = {})
    self.assoc_options[name] = BelongsToOptions.new(name, options)

    define_method(name) do
      options = self.class.assoc_options[name]
      target_key = self.send(options.foreign_key)
        options.model_class.where(options.primary_key => target_key)[0]

    end
  end

  def has_many(name, options = {})
      self.assoc_options[name] = HasManyOptions.new(name, self.name, options)

      define_method(name) do
        options = self.class.assoc_options[name]
        target_key = self.send(options.primary_key)
          options.model_class.where(options.foreign_key => target_key)

      end
  end

  def assoc_options
    @assoc_options ||= {}
    @assoc_options
  end

  def has_one_through(name, through_name, source_name)
    define_method(name) do
      through = self.class.assoc_options[through_name]
      source = through.model_class.assoc_options[source_name]

      target_value = self.send(through.foreign_key)

      results = DBConnection.execute(<<-SQL, target_value)
        SELECT
          #{source.table_name}.*
        FROM
          #{through.table_name}
        JOIN
          #{source.table_name}
        ON
          #{through.table_name}.#{source.foreign_key} = #{source.table_name}.#{source.primary_key}
        WHERE
          #{through.table_name}.#{through.primary_key} = ?
        SQL

        source.model_class.parse_all(results)[0]
      end
  end
end
