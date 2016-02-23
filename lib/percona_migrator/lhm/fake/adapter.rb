module PerconaMigrator
  module Lhm
    module Fake

      class Adapter
        def initialize(migration, table_name)
          @migration = migration
          @table_name = table_name
        end

        # Translates the Lhm's add_column syntax to ActiveRecord's and calls it
        # in the given migration
        def add_column(column_name, definition)
          type = type_from(column_name, definition)
          options = options_from(column_name, definition)

          migration.add_column(table_name, column_name, type, options)
        end

        def remove_column(column_name)
          migration.remove_column(table_name, column_name)
        end

        def add_index(columns, index_name = nil)
          options = { name: index_name } if index_name
          migration.add_index(table_name, columns, options || {})
        end

        def remove_index(columns, index_name = nil)
          options = if index_name
                      { name: index_name }
                    else
                      { column: columns }
                    end
          migration.remove_index(table_name, options)
        end

        def change_column(column_name, definition)
          type = type_from(column_name, definition)
          options = options_from(column_name, definition)

          migration.change_column(table_name, column_name, type, options)
        end

        private

        attr_reader :migration, :table_name

        def type_from(name, definition)
          column(name, definition).type
        end

        # TODO: investigate
        #
        # Rails doesn't take into account lenght argument of INT in the
        # definition, as an integer it will default it to 4 not an integer
        def options_from(name, definition)
          column = column(name, definition)
          { limit: column.limit, default: column.default, null: column.null }
        end

        def column(name, definition)
          @column ||= self.class.column_factory.new(
            name,
            default_value(definition),
            definition,
            null_value(definition)
          )
        end

        def default_value(definition)
          match = /default '?(\w+)'?/i.match(definition)
          if definition =~ /timestamp/i
            match = /default '?(.+[^'])'?/i.match(definition)
          end
          return unless match

          if match
            match[1].downcase != 'null' ? match[1] : nil
          end
        end

        def null_value(definition)
          match = /((\w*) NULL)/i.match(definition)
          return true unless match

          if match
            match[2].downcase == 'not' ? false : true
          end
        end

        def self.column_factory
          ::ActiveRecord::ConnectionAdapters::PerconaMigratorAdapter::Column
        end
      end
    end
  end
end
