## v0.8 [2024-04-06]

_Powerpipe_

[Powerpipe](https://powerpipe.io) is now the preferred way to run this mod!  [Migrating from Steampipe →](https://powerpipe.io/blog/migrating-from-steampipe)

All v0.x versions of this mod will work in both Steampipe and Powerpipe, but v1.0.0 onwards will be in Powerpipe format only.

_Enhancements_

- Focus documentation on Powerpipe commands.
- Show how to combine Powerpipe mods with Steampipe plugins.

## v0.7 [2023-11-03]

_Breaking changes_

- Updated the plugin dependency section of the mod to use `min_version` instead of `version`. ([#79](https://github.com/turbot/steampipe-mod-oci-insights/pull/79))

## v0.6 [2023-08-07]

_Bug fixes_

- Updated the Age Report dashboards to order by the creation time of the resource. ([#73](https://github.com/turbot/steampipe-mod-oci-insights/pull/73))
- Fixed dashboard localhost URLs in README and index doc. ([#72](https://github.com/turbot/steampipe-mod-oci-insights/pull/72))

## v0.5 [2023-01-30]

_Dependencies_

- Steampipe `v0.18.0` or higher is now required ([#69](https://github.com/turbot/steampipe-mod-oci-insights/pull/69))
- OCI plugin `v0.19.0` or higher is now required. ([#69](https://github.com/turbot/steampipe-mod-oci-insights/pull/69))

_What's new?_

- Added resource relationship graphs across all the detail dashboards to highlight the relationship the resource shares with other resources. ([#68](https://github.com/turbot/steampipe-mod-oci-insights/pull/68))
- New dashboards added: ([#68](https://github.com/turbot/steampipe-mod-oci-insights/pull/68))
  - [OCI Identity Group Dashboard](https://hub.steampipe.io/mods/turbot/oci_insights/dashboards/dashboard.identity_group_dashboard)
  - [OCI Identity Group Detail](https://hub.steampipe.io/mods/turbot/oci_insights/dashboards/dashboard.identity_group_detail)
  - [OCI KMS Vault Age Report](https://hub.steampipe.io/mods/turbot/oci_insights/dashboards/dashboard.kms_vault_age_report)
  - [OCI KMS Vault Dashboard](https://hub.steampipe.io/mods/turbot/oci_insights/dashboards/dashboard.kms_vault_dashboard)
  - [OCI KMS Vault Detail](https://hub.steampipe.io/mods/turbot/oci_insights/dashboards/dashboard.kms_vault_detail)

## v0.4 [2022-05-09]

_Enhancements_

- Updated docs/index.md and README to the latest format. ([#61](https://github.com/turbot/steampipe-mod-oci-insights/pull/61))

## v0.3 [2022-03-31]

_Dependencies_

- OCI plugin `v0.11.0` or higher is now required ([#56](https://github.com/turbot/steampipe-mod-oci-insights/pull/56))

_What's new?_

- New dashboards added:
  - [VCN Detail](https://hub.steampipe.io/mods/turbot/oci_insights/dashboards/dashboard.oci_vcn_detail) ([#52](https://github.com/turbot/steampipe-mod-oci-insights/pull/52))

_Enhancements_

- Added monitoring status card and chart to `OCI Compute Instance Dashboard` and `OCI Compute Instance Detail` dashboards ([#50](https://github.com/turbot/steampipe-mod-oci-insights/pull/50))
- Added performance and utilization charts to `OCI Block Storage Boot Volume Dashboard` dashboard ([#49](https://github.com/turbot/steampipe-mod-oci-insights/pull/49))

## v0.2 [2022-03-24]

_Dependencies_

- Steampipe v0.13.1 or higher is now required

_What's new?_

- New dashboards added:
  - [Autonomous Database Detail](https://hub.steampipe.io/mods/turbot/oci_insights/dashboards/dashboard.oci_database_autonomous_database_detail) ([#39](https://github.com/turbot/steampipe-mod-oci-insights/pull/39))
  - [Block Storage Block Volume Detail](https://hub.steampipe.io/mods/turbot/oci_insights/dashboards/dashboard.oci_block_storage_block_volume_detail) ([#39](https://github.com/turbot/steampipe-mod-oci-insights/pull/39))
  - [Block Storage Boot Volume Detail](https://hub.steampipe.io/mods/turbot/oci_insights/dashboards/dashboard.oci_block_storage_boot_volume_detail) ([#39](https://github.com/turbot/steampipe-mod-oci-insights/pull/39))
  - [Compute Instance Detail](https://hub.steampipe.io/mods/turbot/oci_insights/dashboards/dashboard.oci_compute_instance_detail) ([#39](https://github.com/turbot/steampipe-mod-oci-insights/pull/39))
  - [File Storage File System Detail](https://hub.steampipe.io/mods/turbot/oci_insights/dashboards/dashboard.oci_filestorage_filesystem_detail) ([#39](https://github.com/turbot/steampipe-mod-oci-insights/pull/39))
  - [Identity User Detail](https://hub.steampipe.io/mods/turbot/oci_insights/dashboards/dashboard.oci_identity_user_detail) ([#39](https://github.com/turbot/steampipe-mod-oci-insights/pull/39))
  - [KMS Key Detail](https://hub.steampipe.io/mods/turbot/oci_insights/dashboards/dashboard.oci_kms_key_detail) ([#39](https://github.com/turbot/steampipe-mod-oci-insights/pull/39))
  - [MySQL DB System Detail](https://hub.steampipe.io/mods/turbot/oci_insights/dashboards/dashboard.oci_mysql_db_system_detail) ([#39](https://github.com/turbot/steampipe-mod-oci-insights/pull/39))
  - [NoSQL Table Detail](https://hub.steampipe.io/mods/turbot/oci_insights/dashboards/dashboard.oci_nosql_table_detail) ([#39](https://github.com/turbot/steampipe-mod-oci-insights/pull/39))
  - [Object Storage Bucket Detail](https://hub.steampipe.io/mods/turbot/oci_insights/dashboards/dashboard.oci_objectstorage_bucket_detail) ([#39](https://github.com/turbot/steampipe-mod-oci-insights/pull/39))
  - [Notification Topic Detail](https://hub.steampipe.io/mods/turbot/oci_insights/dashboards/dashboard.oci_ons_notification_topic_detail) ([#39](https://github.com/turbot/steampipe-mod-oci-insights/pull/39))

## v0.1 [2022-03-10]

_What's new?_

New dashboards, reports, and details for the following services:
- Block Storage
- Compute
- Database
- File Storage
- Identity
- KMS
- MySQL
- NoSQL
- Object Storage
- ONS
- VCN
