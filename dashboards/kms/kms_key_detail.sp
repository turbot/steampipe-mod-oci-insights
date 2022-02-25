query "oci_kms_key_input" {
  sql = <<EOQ
    select
      id as label,
      id as value
    from
      oci_kms_key
    where
      lifecycle_state <> 'DELETED'
    order by
      id;
EOQ
}

query "oci_kms_key_name_for_key" {
  sql = <<-EOQ
    select
      name as "Key"
    from
      oci_kms_key
    where
      id = $1 and lifecycle_state <> 'DELETED';
  EOQ

  param "id" {}
}

query "oci_kms_key_disabled_for_key" {
  sql = <<-EOQ
    select
      lifecycle_state as value,
      'Lifecycle State' as label,
      case when lifecycle_state = 'DISABLED' then 'alert' else 'ok' end as type
    from
      oci_kms_key
    where
      id = $1 and lifecycle_state <> 'DELETED';
  EOQ

  param "id" {}
}

query "oci_kms_key_protection_mode_for_key" {
  sql = <<-EOQ
    select
      protection_mode as "Protection Mode"
    from
      oci_kms_key
    where
      id = $1 and lifecycle_state <> 'DELETED';
  EOQ

  param "id" {}
}

dashboard "oci_kms_key_detail" {
  title = "OCI KMS Key Detail"

  input "key_id" {
    title = "Select a key:"
    sql   = query.oci_kms_key_input.sql
    width = 4
  }

  container {

    # Assessments
    card {
      width = 2

      query = query.oci_kms_key_name_for_key
      args = {
        id = self.input.key_id.value
      }
    }

    card {
      width = 2

      query = query.oci_kms_key_disabled_for_key
      args = {
        id = self.input.key_id.value
      }
    }

    card {
      query = query.oci_kms_key_protection_mode_for_key
      type  = "info"
      width = 2

      args = {
        id = self.input.key_id.value
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
            time_of_deletion as "Time Of Deletion",
            vault_name as "Vault Name",
            length as "Length",
            id as "OCID",
            compartment_id as "Compartment ID"
          from
            oci_kms_key
          where
           id = $1 and lifecycle_state <> 'DELETED';
        EOQ

        param "id" {}

        args = {
          id = self.input.key_id.value
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
              oci_kms_key
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
          id = self.input.key_id.value
        }

      }
    }

    container {
      width = 6

      table {
        title = "Algorithm"
        sql   = <<-EOQ
          select
            name as "Name",
            time_created as "Time Created",
            algorithm as "Algorithm"
          from
            oci_kms_key
          where
           id  = $1 and lifecycle_state <> 'DELETED';
        EOQ

        param "id" {}

        args = {
          id = self.input.key_id.value
        }
      }
    }

  }
}
