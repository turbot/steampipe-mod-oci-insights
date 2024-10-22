mod "oci_insights" {
  # hub metadata
  title         = "Oracle Cloud Infrastructure Insights"
  description   = "Create dashboards and reports for your Oracle Cloud Infrastructure resources using Powerpipe and Steampipe."
  color         = "#F80000"
  documentation = file("./docs/index.md")
  icon          = "/images/mods/turbot/oci-insights.svg"
  categories    = ["oci", "dashboard", "public cloud"]

  opengraph {
    title       = "Powerpipe Mod for OCI Insights"
    description = "Create dashboards and reports for your Oracle Cloud Infrastructure resources using Powerpipe and Steampipe."
    image       = "/images/mods/turbot/oci-insights-social-graphic.png"
  }

  require {
    plugin "oci" {
      min_version = "0.19.0"
    }
  }
}
