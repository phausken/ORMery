require_relative 'sql_object'
require_relative 'searchable'
require 'active_support/inflector'

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

class SQLObject
  include Associatable
  extend Associatable
end
