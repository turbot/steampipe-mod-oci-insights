dashboard "nosql_table_detail" {

  title = "OCI NoSQL Table Detail"

  tags = merge(local.nosql_common_tags, {
    type = "Detail"
  })

  input "table_id" {
    title = "Select a table:"
    query = query.nosql_table_input
    width = 4
  }

  container {

    card {
      width = 2

      query = query.nosql_table_state
      args = [self.input.table_id.value]
    }

    card {
      width = 2

      query = query.nosql_table_auto_reclaimable
      args = [self.input.table_id.value]
    }
  }

  with "nosql_table_parents" {
    query = query.nosql_table_nosql_table_parents
    args  = [self.input.table_id.value]
  }

  with "nosql_table_children" {
    query = query.nosql_table_nosql_table_children
    args  = [self.input.table_id.value]
  }

  container {

    graph {
      title     = "Relationships"
      type      = "graph"
      direction = "TD"

      node {
        base = node.nosql_table
        args = {
          nosql_table_ids = [self.input.table_id.value]
        }
      }

      node {
        base = node.nosql_table
        args = {
          nosql_table_ids = with.nosql_table_parents.rows[*].parent_table_id
        }
      }

      node {
        base = node.nosql_table
        args = {
          nosql_table_ids = with.nosql_table_children.rows[*].child_table_id
        }
      }

      edge {
        base = edge.nosql_table_parent_to_nosql_table
        args = {
          nosql_table_ids = with.nosql_table_parents.rows[*].parent_table_id
        }
      }

      edge {
        base = edge.nosql_table_parent_to_nosql_table
        args = {
          nosql_table_ids = [self.input.table_id.value]
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
        query = query.nosql_table_overview
        args = [self.input.table_id.value]

      }

      table {
        title = "Tags"
        width = 6
        query = query.nosql_table_tag
        args = [self.input.table_id.value]

      }
    }

    container {
      width = 6

      table {
        title = "Table Limits"
        query = query.nosql_table_limits
        args = [self.input.table_id.value]
      }

      table {
        title = "Column Details"
        query = query.nosql_table_column
        args = [self.input.table_id.value]
      }

    }

    container {

      width = 12

      chart {
        title = "Read Throttle Count Daily - Last 7 Days"
        type  = "line"
        width = 6
        query = query.nosql_table_read_throttle
        args = [self.input.table_id.value]
      }

      chart {
        title = "Write Throttle Count Daily - Last 7 Days"
        type  = "line"
        width = 6
        query = query.nosql_table_write_throttle
        args = [self.input.table_id.value]
      }

    }

  }
}

# Input queries

query "nosql_table_input" {
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

# With queries

query "nosql_table_nosql_table_parents" {
  sql = <<EOQ
    with parent_name as (
      select
        split_part(c_name, '.', (array_length(string_to_array(c_name, '.'),1)-1)) as parent_table_name,
        c_name,
        id as child_id
      from (
        select
          name as c_name,
          id
        from
          oci_nosql_table
        ) as a
      where
        (array_length(string_to_array(c_name, '.'),1)-1) > 0
    ),
    all_parent_name as (
      select
        split_part(pn.c_name, pn.parent_table_name, 1) || parent_table_name as parent_name,
        child_id
      from
        parent_name as pn
    )
    select
      p.id as parent_table_id
    from
      oci_nosql_table as p,
      all_parent_name as pn
    where
      p.name = pn.parent_name
      and pn.child_id = $1;
  EOQ
}

query "nosql_table_nosql_table_children" {
  sql = <<EOQ
    with parent_name as (
      select
        split_part(c_name, '.', (array_length(string_to_array(c_name, '.'),1)-1)) as parent_table_name,
        c_name,
        id as child_id
      from (
        select
          name as c_name,
          id
        from
          oci_nosql_table
        ) as a
      where
        (array_length(string_to_array(c_name, '.'),1)-1) > 0
    ),
    all_parent_name as (
      select
        split_part(pn.c_name, pn.parent_table_name, 1) || parent_table_name as parent_name,
        child_id
      from
        parent_name as pn
    )
    select
      pn.child_id as child_table_id
    from
      oci_nosql_table as p
      left join all_parent_name as pn on p.name = pn.parent_name
    where
      pn.child_id is not null
      and p.id like $1;
  EOQ
}

# Card queries

query "nosql_table_state" {
  sql = <<-EOQ
    select
      initcap(lifecycle_state) as "State"
    from
      oci_nosql_table
    where
      id = $1;
  EOQ
}

query "nosql_table_auto_reclaimable" {
  sql = <<-EOQ
    select
      case when is_auto_reclaimable then 'Enabled' else 'Disabled' end as "Auto Reclaimable"
    from
      oci_nosql_table
    where
      id = $1;
  EOQ
}

# Other detail page queries

query "nosql_table_overview" {
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
      id = $1;
  EOQ
}

query "nosql_table_tag" {
  sql = <<-EOQ
    with jsondata as (
    select
      tags::json as tags
    from
      oci_nosql_table
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

query "nosql_table_limits" {
  sql = <<-EOQ
    select
      table_limits ->> 'maxReadUnits' as "Max Read Units",
      table_limits ->> 'maxStorageInGBs' as "Max Storage In GBs",
      table_limits ->> 'maxWriteUnits' as "Max Write Units"
    from
      oci_nosql_table
    where
      id  = $1;
  EOQ
}

query "nosql_table_column" {
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
      id = $1;
  EOQ
}

query "nosql_table_read_throttle" {
  sql = <<-EOQ
    select
      d.timestamp,
      (sum / 86400) as read_throttle_count_daily
    from
      oci_nosql_table_metric_read_throttle_count_daily as d
      left join oci_nosql_table as t on d.name = t.name
    where
      d.timestamp >= current_date - interval '7 day' and t.id = $1
    order by d.timestamp;
  EOQ
}

query "nosql_table_write_throttle" {
  sql = <<-EOQ
   select
      d.timestamp,
      (sum / 86400) as write_throttle_count_daily
    from
      oci_nosql_table_metric_write_throttle_count_daily as d
      left join oci_nosql_table as t on d.name = t.name
    where
      d.timestamp >= current_date - interval '7 day' and t.id = $1
    order by d.timestamp;
  EOQ
}
