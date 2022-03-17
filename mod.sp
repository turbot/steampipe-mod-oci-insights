mod "oci_insights" {
  # hub metadata
  title         = "Oracle Cloud Infrastructure Insights"
  description   = "Create dashboards and reports for your Oracle Cloud Infrastructure resources using Steampipe."
  color         = "#F80000"
  documentation = file("./docs/index.md")
  icon          = "/images/mods/turbot/oci-insights.svg"
  categories    = ["oci", "dashboard", "public cloud"]

  opengraph {
    title        = "Steampipe Mod for OCI Insights"
    description  = "Create dashboards and reports for your Oracle Cloud Infrastructure resources using Steampipe."
    image        = "/images/mods/turbot/oci-insights-social-graphic.png"
  }

  require {
    plugin "oci" {
      version = "0.9.0"
    }
  }
}
