# frozen_string_literal: true

module ActiveRecord
  module PostgresEnum
    module PostgreSQLAdapter
      DEFINED_ENUMS_QUERY = <<~SQL
        SELECT t.OID, t.typname, t.typtype, array_agg(e.enumlabel) as enumlabels
        FROM pg_type t
        INNER JOIN pg_enum e ON e.enumtypid = t.oid
        WHERE typtype = 'e'
        GROUP BY t.OID, t.typname, t.typtype
        ORDER BY t.typname
      SQL

      def enums
        select_all(DEFINED_ENUMS_QUERY).each_with_object({}) do |row, memo|
          memo[row["typname"].to_sym] = row['enumlabels'].gsub(/[{}]/, '').split(',')
        end
      end

      def create_enum(name, values)
        values = values.map { |v| "'#{v}'" }
        execute "CREATE TYPE #{name} AS ENUM (#{values.join(', ')})"
      end

      def drop_enum(name)
        execute "DROP TYPE #{name}"
      end

      def rename_enum(name, new_name)
        execute "ALTER TYPE #{name} RENAME TO #{new_name}"
      end

      def add_enum_value(name, value)
        execute "ALTER TYPE #{name} ADD VALUE '#{value}'"
      end

      def rename_enum_value(name, existing_value, new_value)
        execute "ALTER TYPE #{name} RENAME VALUE '#{existing_value}' TO '#{new_value}'"
      end

      def migration_keys
        super + [:enum_name]
      end

      def prepare_column_options(column, types)
        spec = super(column, types)
        spec[:enum_name] = column.cast_type.enum_name.inspect if column.type == :enum
        spec
      end
    end
  end
end