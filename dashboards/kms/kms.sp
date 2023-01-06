locals {
  kms_common_tags = {
    service = "OCI/KMS"
  }
}

category "kms_key" {
  title = "KMS Key"
  color = local.security_color
  href  = "/oci_insights.dashboard.kms_key_detail?input.key_id={{.properties.'ID' | @uri}}"
  icon  = "key"
}

category "kms_key_version" {
  title = "KMS Key Version"
  color = local.security_color
  icon  = "key"
}

category "kms_vault" {
  title = "KMS Vault"
  color = local.security_color
  icon  = "key"
}

category "kms_vault_secret" {
  title = "KMS Vault Secret"
  color = local.security_color
  icon  = "enhanced_encryption"
}