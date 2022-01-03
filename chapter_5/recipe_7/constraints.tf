data "google_organization" "current" {
  domain = var.organization_domain
}

resource "google_organization_policy" "shared_vpc_projects" {
  org_id     = data.google_organization.current.org_id
  constraint = "constraints/compute.restrictSharedVpcHostProjects"

  list_policy {
    allow {
      values = ["projects/${var.hub_project}"]
    }
  }
}

resource "google_organization_policy" "shared_vpc_lien_removal" {
  org_id     = data.google_organization.current.org_id
  constraint = "constraints/compute.restrictXpnProjectLienRemoval"

  boolean_policy {
    enforced = true
  }
}

resource "google_organization_policy" "shared_vpc_subnetworks" {
  org_id     = data.google_organization.current.org_id
  constraint = "constraints/compute.restrictSharedVpcSubnetworks"

  list_policy {
    allow {
      values = [
        for subnet in google_compute_subnetwork.subnet : subnet.id
      ]
    }
  }
}
