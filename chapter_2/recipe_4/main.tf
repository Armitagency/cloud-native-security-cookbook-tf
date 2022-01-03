data "google_organization" "this" {
  domain = var.organization_domain
}

resource "google_organization_policy" "region_lock" {
  org_id     = data.google_organization.this.org_id
  constraint = "constraints/gcp.resourceLocations"

  list_policy {
    allow {
      values = ["in:${var.allowed_location}"]
    }
  }
}
