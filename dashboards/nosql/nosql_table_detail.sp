dashboard "oci_nosql_table_detail" {

  title = "OCI NoSQL Table Detail"

  tags = merge(local.nosql_common_tags, {
    type = "Detail"
  })

  input "table_id" {
    title = "Select a table:"
    query = query.oci_nosql_table_input
    width = 4
  }

  container {

    container {
      width = 6

      table {
        title = "Overview"
        type  = "line"
        width = 6
        query = query.oci_nosql_table_overview
        args = {
          id = self.input.table_id.value
        }

      }

      table {
        title = "Tags"
        width = 6
        query = query.oci_nosql_table_tag
        args = {
          id = self.input.table_id.value
        }

      }
    }

    container {
      width = 6

      table {
        title = "Table Limits"
        query = query.oci_nosql_table_limits
        args = {
          id = self.input.table_id.value
        }
      }

      table {
        title = "Column Details"
        query = query.oci_nosql_table_column
        args = {
          id = self.input.table_id.value
        }
      }

      table {
        title = "DDL Statement"
        query = query.oci_nosql_table_ddl
        args = {
          id = self.input.table_id.value
        }
      }
    }

    container {

      width = 12

      chart {
        title = "Read Throttle Count - Last 7 Days"
        type  = "line"
        width = 6
        query = query.oci_nosql_table_read_throttle
        args = {
          id = self.input.table_id.value
        }
      }

      chart {
        title = "Write Throttle Count - Last 7 Days"
        type  = "line"
        width = 6
        query = query.oci_nosql_table_write_throttle
        args = {
          id = self.input.table_id.value
        }
      }

    }

  }
}

query "oci_nosql_table_input" {
  sql = <<EOQ
    select
      n.name as label,
      n.id as value,
      json_build_object(
        'c.name', coalesce(c.title, 'root'),
        'n.region', region,
        't.name', t.name
      ) as tags
    from
      oci_nosql_table as n
      left join oci_identity_compartment as c on n.compartment_id = c.id
      left join oci_identity_tenancy as t on n.tenant_id = t.id
    where
      n.lifecycle_state <> 'DELETED'
    order by
      n.name;
EOQ
}

query "oci_nosql_table_overview" {
  sql = <<-EOQ
    select
      name as "Name",
      time_created as "Time Created",
      time_of_expiration as "Time Of Expiration",
      region as "Region",
      id as "OCID",
      compartment_id as "Compartment ID"
    from
      oci_nosql_table
    where
      id = $1 and lifecycle_state <> 'DELETED';
  EOQ

  param "id" {}
}

query "oci_nosql_table_tag" {
  sql = <<-EOQ
    with jsondata as (
    select
      tags::json as tags
    from
      oci_nosql_table
    where
      id = $1 and lifecycle_state <> 'DELETED'
    )
    select
      key as "Key",
      value as "Value"
    from
      jsondata,
      json_each_text(tags);
  EOQ

  param "id" {}
}

query "oci_nosql_table_limits" {
  sql = <<-EOQ
    select
      table_limits ->> 'maxReadUnits' as "Max Read Units",
      table_limits ->> 'maxStorageInGBs' as "Max Storage In GBs",
      table_limits ->> 'maxWriteUnits' as "Max Write Units"
    from
      oci_nosql_table
    where
      id  = $1 and lifecycle_state <> 'DELETED';
  EOQ

  param "id" {}
}

query "oci_nosql_table_column" {
  sql = <<-EOQ
    select
      c ->> 'name' as "Name",
      c ->> 'defaultValue' as "Default Value",
      c ->> 'isNullable' as "Nullable",
      c ->> 'type' as "Type"
    from
      oci_nosql_table,
      jsonb_array_elements(schema -> 'columns') as c
    where
      id = $1 and lifecycle_state <> 'DELETED';
  EOQ

  param "id" {}
}

query "oci_nosql_table_ddl" {
  sql = <<-EOQ
    select
      ddl_statement as "Statement"
    from
      oci_nosql_table
    where
      id = $1 and lifecycle_state <> 'DELETED';
  EOQ

  param "id" {}
}

query "oci_nosql_table_read_throttle" {
  sql = <<-EOQ
    select
      h.timestamp,
      (sum / 300) as read_throttle_count
    from
      oci_nosql_table_metric_read_throttle_count as h
      left join oci_nosql_table as t on h.name = t.name
    where
      h.timestamp >= current_date - interval '7 day' and t.id = $1
    order by h.timestamp;
  EOQ

  param "id" {}
}

query "oci_nosql_table_write_throttle" {
  sql = <<-EOQ
   select
      h.timestamp,
      (sum / 300) as write_throttle_count
    from
      oci_nosql_table_metric_write_throttle_count as h
      left join oci_nosql_table as t on h.name = t.name
    where
      h.timestamp >= current_date - interval '7 day' and t.id = $1
    order by h.timestamp;
  EOQ

  param "id" {}
}
