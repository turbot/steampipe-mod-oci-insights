query "oci_nosql_table_input" {
  sql = <<EOQ
    select
      id as label,
      id as value
    from
      oci_nosql_table
    where
      lifecycle_state <> 'DELETED'
    order by
      id;
EOQ
}

query "oci_nosql_table_name_for_table" {
  sql = <<-EOQ
    select
      name as "Table"
    from
      oci_nosql_table
    where
      id = $1 and lifecycle_state <> 'DELETED';
  EOQ

  param "id" {}
}

query "oci_nosql_table_stalled_more_than_90_days_for_table" {
  sql = <<-EOQ
    select
      case when date_part('day', now()-(time_updated::timestamptz)) > 90 then 'True' else 'False' end as value,
      'Stalled > 90 Days' as label,
      case when date_part('day', now()-(time_updated::timestamptz)) > 90 then 'alert' else 'ok' end as type
    from
      oci_nosql_table
    where
       id = $1 and lifecycle_state <> 'DELETED';
  EOQ

  param "id" {}
}

query "oci_nosql_table_auto_reclaimable_for_table" {
  sql = <<-EOQ
    select
      case when is_auto_reclaimable then 'Enabled' else 'Disabled' end as "Auto Reclaimable"
    from
      oci_nosql_table
    where
      id = $1 and lifecycle_state <> 'DELETED';
  EOQ

  param "id" {}
}

dashboard "oci_nosql_table_detail" {
  title = "OCI NoSQL Table Detail"

  input "table_id" {
    title = "Select a table:"
    sql   = query.oci_nosql_table_input.sql
    width = 4
  }

  container {

    # Assessments
    card {
      width = 2

      query = query.oci_nosql_table_name_for_table
      args = {
        id = self.input.table_id.value
      }
    }

    card {
      width = 2

      query = query.oci_nosql_table_stalled_more_than_90_days_for_table
      args = {
        id = self.input.table_id.value
      }
    }

    card {
      query = query.oci_nosql_table_auto_reclaimable_for_table
      type  = "info"
      width = 2

      args = {
        id = self.input.table_id.value
      }
    }

  }

  container {

    container {
      width = 6

      table {
        title = "Overview"
        type  = "line"
        width = 6

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

        args = {
          id = self.input.table_id.value
        }

      }

      table {
        title = "Tags"
        width = 6

        sql = <<-EOQ
          WITH jsondata AS (
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

        args = {
          id = self.input.table_id.value
        }

      }
    }

    container {
      width = 6

      table {
        title = "Table Limits"
        sql   = <<-EOQ
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

        args = {
          id = self.input.table_id.value
        }
      }
    }

  }
}
