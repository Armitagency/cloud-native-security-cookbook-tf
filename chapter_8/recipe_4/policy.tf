resource "google_os_config_guest_policies" "stackdriver_agent" {
  provider        = google-beta
  guest_policy_id = "debian-stackdriver-agent"

  assignment {
    os_types {
      os_short_name = "debian"
    }
  }

  packages {
    name          = "stackdriver-agent"
    desired_state = "INSTALLED"
  }

  package_repositories {
    apt {
      uri          = "https://packages.cloud.google.com/apt"
      archive_type = "DEB"
      distribution = "google-cloud-monitoring-buster-all"
      components   = ["main"]
      gpg_key      = "https://packages.cloud.google.com/apt/doc/apt-key.gpg"
    }
  }
}
