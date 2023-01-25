dashboard "kms_vault_detail" {

  title         = "OCI KMS Vault Detail"
  documentation = file("./dashboards/kms/docs/kms_vault_detail.md")

  tags = merge(local.kms_common_tags, {
    type = "Detail"
  })

  input "kms_vault_id" {
    title = "Select a vault:"
    query = query.key_vault_input
    width = 4
  }

  container {

    card {
      width = 2
      query = query.kms_vault_disabled
      args  = [self.input.kms_vault_id.value]
    }

    card {
      width = 2
      query = query.kms_vault_type
      args  = [self.input.kms_vault_id.value]
    }

  }

  with "kms_keys_for_kms_vault" {
    query = query.kms_keys_for_kms_vault
    args  = [self.input.kms_vault_id.value]
  }

  with "kms_vault_secrets_for_kms_vault" {
    query = query.kms_vault_secrets_for_kms_vault
    args  = [self.input.kms_vault_id.value]
  }

  container {

    graph {
      title     = "Relationships"
      type      = "graph"
      direction = "TD"

      node {
        base = node.kms_vault
        args = {
          kms_vault_ids = [self.input.kms_vault_id.value]
        }
      }

      node {
        base = node.kms_key
        args = {
          kms_key_ids = with.kms_keys_for_kms_vault.rows[*].kms_key_id
        }
      }

      node {
        base = node.kms_vault_secret
        args = {
          kms_vault_secret_ids = with.kms_vault_secrets_for_kms_vault.rows[*].secret_id
        }
      }

      edge {
        base = edge.kms_vault_to_kms_key
        args = {
          kms_vault_ids = [self.input.kms_vault_id.value]
        }
      }

      edge {
        base = edge.kms_key_to_kms_vault_secret
        args = {
          kms_key_ids = with.kms_keys_for_kms_vault.rows[*].kms_key_id
        }
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
        query = query.kms_vault_overview
        args  = [self.input.kms_vault_id.value]

      }

      table {
        title = "Tags"
        width = 6
        query = query.kms_vault_tags
        args  = [self.input.kms_vault_id.value]
      }
    }

    container {
      width = 6

      table {
        title = "Endpoints"
        query = query.kms_vault_endpoints
        args  = [self.input.kms_vault_id.value]
      }

    }

  }

}

# Input queries

query "key_vault_input" {
  sql = <<-EOQ
    select
      k.display_name as label,
      k.id as value,
      json_build_object(
        'c.name', coalesce(c.title, 'root'),
        'k.region', region,
        't.name', t.name
      ) as tags
    from
      oci_kms_vault as k
      left join oci_identity_compartment as c on k.compartment_id = c.id
      left join oci_identity_tenancy as t on k.tenant_id = t.id
    where
      k.lifecycle_state <> 'DELETED'
    order by
      k.display_name;
  EOQ
}

# with queries

query "kms_keys_for_kms_vault" {
  sql = <<-EOQ
    select
      id as kms_key_id
    from
      oci_kms_key
    where
      vault_id = $1;
  EOQ
}

query "kms_vault_secrets_for_kms_vault" {
  sql = <<-EOQ
    select
      id as secret_id
    from
      oci_vault_secret
    where
      vault_id = $1;
  EOQ
}

# card queries

query "kms_vault_disabled" {
  sql = <<-EOQ
    select
      initcap(lifecycle_state) as value,
      'Lifecycle State' as label,
      case when lifecycle_state = 'DISABLED' then 'alert' else 'ok' end as type
    from
      oci_kms_vault
    where
      id = $1;
  EOQ

}

query "kms_vault_type" {
  sql = <<-EOQ
    select
      'Vault Type' as label,
      vault_type as value
    from
      oci_kms_vault
    where
      id = $1;
  EOQ

}

# Other detail page queries

query "kms_vault_overview" {
  sql = <<-EOQ
    select
      title as "Title",
      id as "ID",
      display_name as "Display Name",
      lifecycle_state as "Lifecycle State",
      time_created as "Time Created",
      compartment_id as "Compartment ID",
      region as "Region"
    from
      oci_kms_vault
    where
      id = $1
  EOQ

}

query "kms_vault_tags" {
  sql = <<-EOQ
    with jsondata as (
    select
      tags::json as tags
    from
      oci_kms_vault
    where
      id = $1
    )
    select
      key as "Key",
      value as "Value"
    from
      jsondata,
      json_each_text(tags);
    EOQ

}

query "kms_vault_endpoints" {
  sql = <<-EOQ
    select
      crypto_endpoint as "Crypto Endpoint",
      management_endpoint as "Management Endpoint"
    from
      oci_kms_vault
    where
      id = $1;
  EOQ

}