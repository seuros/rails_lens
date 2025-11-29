# frozen_string_literal: true

# <rails-lens:schema:begin>
# table = "tenant_settings"
# database_dialect = "PostgreSQL"
#
# columns = [
#   { name = "tenant_id", type = "integer", null = false },
#   { name = "key", type = "string", null = false },
#   { name = "value", type = "text" },
#   { name = "description", type = "text" },
#   { name = "encrypted", type = "boolean", default = "false" },
#   { name = "created_at", type = "datetime", null = false },
#   { name = "updated_at", type = "datetime", null = false }
# ]
#
# indexes = [
#   { name = "index_tenant_settings_on_key", columns = ["key"] },
#   { name = "index_tenant_settings_on_tenant_id", columns = ["tenant_id"] }
# ]
#
# [composite_pk]
# keys = ["tenant_id", "key"]
#
# notes = ["value:NOT_NULL", "description:NOT_NULL", "encrypted:NOT_NULL", "key:LIMIT", "value:STORAGE", "description:STORAGE"]
# <rails-lens:schema:end>
class TenantSetting < ApplicationRecord
  # Composite primary key: [tenant_id, key]
  # Note: Rails doesn't natively support composite primary keys
  # Consider using a gem like composite_primary_keys if needed
end

