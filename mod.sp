mod "oci_insights" {
  # hub metadata
  title         = "OCI Insights"
  description   = "Create dashboards and reports for your OCI resources using Steampipe."
  color         = "#FF9900"
  documentation = file("./docs/index.md")
  icon          = "/images/mods/turbot/oci-insights.svg"
  categories    = ["oci", "insights", "public cloud"]

  opengraph {
    title        = "Steampipe Mod for OCI Insights"
    description  = "Create dashboards and reports for your OCI resources using Steampipe."
    image        = "/images/mods/turbot/oci-insights-social-graphic.png"
  }
}