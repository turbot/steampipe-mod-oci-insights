      with tenancy_details as (
          select
            id,
            title
          from
            oci_identity_tenancy
      ),

        compartments as (
            select
              id,
              title
            from
              oci_identity_compartment
            where lifecycle_state = 'ACTIVE'
          )

        select
          v.display_name as "Name",
          -- date_trunc('day',age(now(),v.time_created))::text as "Age",
          now()::date - v.time_created::date as "Age in Days",
          v.time_created as "Create Time",
          v.lifecycle_state as "Lifecycle State",
          a.title as "Compartment",
          t.title as "Tenancy",
          v.region,
          v.id as "OCID"
        from
          oci_database_autonomous_database as v
          left join compartments as a on v.compartment_id = a.id
          left join tenancy_details as t on v.tenant_id = t.id
          -- compartments as a
        where
          v.lifecycle_state <> 'DELETED'
        order by
          v.time_created,
          v.title


--


select
          v.display_name as "Name",
          now()::date - v.time_created::date as "Age in Days",
          v.time_created as "Create Time",
          v.lifecycle_state as "Lifecycle State",
          coalesce(c.title, 'root') as "Compartment",
          t.title as "Tenancy",
          v.region as "Region",
          v.id as "OCID"
        from
          oci_mysql_backup as v
          left join oci_identity_compartment as c on v.compartment_id = c.id
          left join oci_identity_tenancy as t on v.tenant_id = t.id
        where
          v.lifecycle_state <> 'DELETED'
        order by
          v.time_created,
          v.title


