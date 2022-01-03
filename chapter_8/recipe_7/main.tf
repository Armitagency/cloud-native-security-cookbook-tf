resource "google_os_config_patch_deployment" "patch" {
  project             = var.project
  patch_deployment_id = "debian-patching"

  instance_filter {
    group_labels {
      labels = {
        os = "debian"
      }
    }
  }

  patch_config {
    reboot_config = "ALWAYS"

    apt {
      type = "DIST"
    }
  }

  recurring_schedule {
    time_zone {
      id = var.time_zone
    }

    dynamic "time_of_day" {
      for_each = toset([var.time_of_day])
      content {
        hours   = time_of_day.value["hours"]
        minutes = time_of_day.value["minutes"]
        seconds = time_of_day.value["seconds"]
        nanos   = 0
      }
    }

    monthly {
      week_day_of_month {
        week_ordinal = var.week_ordinal
        day_of_week  = var.day_of_week
      }
    }
  }

  rollout {
    mode = "ZONE_BY_ZONE"
    disruption_budget {
      percentage = var.disruption_budget
    }
  }
}
