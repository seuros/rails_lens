# frozen_string_literal: true

# <rails-lens:schema:begin>
# table = "tenant_settings"
# database_dialect = "PostgreSQL"
#
# columns = [
#   { name = "tenant_id", type = "integer", nullable = false },
#   { name = "key", type = "string", nullable = false },
#   { name = "value", type = "text", nullable = true },
#   { name = "description", type = "text", nullable = true },
#   { name = "encrypted", type = "boolean", nullable = true, default = "false" },
#   { name = "created_at", type = "datetime", nullable = false },
#   { name = "updated_at", type = "datetime", nullable = false }
# ]
#
# indexes = [
#   { name = "index_tenant_settings_on_key", columns = ["key"] },
#   { name = "index_tenant_settings_on_tenant_id", columns = ["tenant_id"] }
# ]
#
# == Composite Primary Key
# Primary Keys: tenant_id, key
#
# == Notes
# - Column 'value' should probably have NOT NULL constraint
# - Column 'description' should probably have NOT NULL constraint
# - Column 'encrypted' should probably have NOT NULL constraint
# - String column 'key' has no length limit - consider adding one
# - Large text column 'description' is frequently queried - consider separate storage
# <rails-lens:schema:end>
class TenantSetting < ApplicationRecord
  # Composite primary key: [tenant_id, key]
  # Note: Rails doesn't natively support composite primary keys
  # Consider using a gem like composite_primary_keys if needed
end

