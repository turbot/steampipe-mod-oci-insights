dashboard "oci_kms_key_detail" {

  title = "OCI KMS Key Detail"

  tags = merge(local.kms_common_tags, {
    type = "Detail"
  })

  input "key_id" {
    title = "Select a key:"
    query = query.oci_kms_key_input
    width = 4
  }

  container {

    card {
      width = 2

      query = query.oci_kms_key_disabled
      args = {
        id = self.input.key_id.value
      }
    }

    card {
      query = query.oci_kms_key_protection_mode
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
        query = query.oci_kms_key_overview
        args = {
          id = self.input.key_id.value
        }

      }

      table {
        title = "Tags"
        width = 6
        query = query.oci_kms_key_tag
        args = {
          id = self.input.key_id.value
        }

      }
    }

    container {
      width = 6

      table {
        title = "Key Details"
        query = query.oci_kms_key_detail
        args = {
          id = self.input.key_id.value
        }
      }
    }

  }
}

query "oci_kms_key_input" {
  sql = <<EOQ
    select
      k.name as label,
      k.id as value,
      json_build_object(
        'c.name', coalesce(c.title, 'root'),
        'k.region', region,
        't.name', t.name
      ) as tags
    from
      oci_kms_key as k
      left join oci_identity_compartment as c on k.compartment_id = c.id
      left join oci_identity_tenancy as t on k.tenant_id = t.id
    where
      k.lifecycle_state <> 'DELETED'
    order by
      k.name;
EOQ
}

query "oci_kms_key_disabled" {
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

query "oci_kms_key_protection_mode" {
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

query "oci_kms_key_overview" {
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
}

query "oci_kms_key_tag" {
  sql = <<-EOQ
    with jsondata as (
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
}

query "oci_kms_key_detail" {
  sql = <<-EOQ
    select
      algorithm as "Algorithm",
      curve_id as "Curve ID",
      length as "Length"
    from
      oci_kms_key
    where
      id  = $1 and lifecycle_state <> 'DELETED';
  EOQ

  param "id" {}
}

