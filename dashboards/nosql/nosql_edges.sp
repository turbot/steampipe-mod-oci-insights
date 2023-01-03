edge "nosql_table_parent_to_nosql_table" {
  title = "child table"

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
      p.id as from_id,
      pn.child_id as to_id
    from
      oci_nosql_table as p,
      all_parent_name as pn
    where
      p.name = pn.parent_name
      and p.id = any($1);
  EOQ

  param "nosql_table_ids" {}
}