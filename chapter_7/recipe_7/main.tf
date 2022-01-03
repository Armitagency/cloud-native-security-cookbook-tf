data "google_organization" "current" {
  domain = var.organization_domain
}

resource "google_organization_policy" "vm_external_ips" {
  org_id     = data.google_organization.current.org_id
  constraint = "constraints/compute.vmExternalIpAccess"

  list_policy {
    deny {
      all = true
    }
  }
}

resource "google_folder_organization_policy" "vpc_connected_functions" {
  folder     = var.target_folder_id
  constraint = "constraints/cloudfunctions.requireVPCConnector"

  boolean_policy {
    enforced = true
  }
}

resource "google_project_organization_policy" "restricted_function_ingress" {
  project    = var.target_project_id
  constraint = "constraints/cloudfunctions.allowedIngressSettings"

  list_policy {
    allow {
      values = [
        "ALLOW_INTERNAL_ONLY"
      ]
    }
  }
}
