resource "google_compute_resource_policy" "daily_snapshot" {
  name = "daily-snapshots"
  snapshot_schedule_policy {
    schedule {
      daily_schedule {
        days_in_cycle = 1
        start_time    = var.start_time_utc
      }
    }
    retention_policy {
      max_retention_days    = 10
      on_source_disk_delete = "APPLY_RETENTION_POLICY"
    }
    snapshot_properties {
      guest_flush       = true
      storage_locations = var.storage_locations
    }
  }
}

resource "google_compute_disk_resource_policy_attachment" "attachment" {
  name = google_compute_resource_policy.daily_snapshot.name
  disk = google_compute_disk.zonal.name
  zone = "${var.region}-${var.zone}"
}

resource "google_compute_disk" "zonal" {
  name = "daily-snapshot"
  size = 10
  type = "pd-ssd"
  zone = "${var.region}-${var.zone}"
}

resource "google_compute_region_disk" "regional" {
  name = "daily-snapshot"
  replica_zones = [
    "${var.region}-${var.zone}",
    "${var.region}-${var.secondary_zone}"
  ]
  size   = 10
  type   = "pd-ssd"
  region = var.region
}

resource "google_compute_region_disk_resource_policy_attachment" "snapshot" {
  name   = google_compute_resource_policy.daily_snapshot.name
  disk   = google_compute_region_disk.regional.name
  region = var.region
}

resource "google_logging_metric" "snapshot_failures" {
  name   = "snapshot_failures"
  filter = <<FILTER
resource.type="gce_disk"
logName="projects/${var.project}/logs/cloudaudit.googleapis.com%2Fsystem_event"
protoPayload.methodName="ScheduledSnapshots"
severity="INFO"
FILTER
  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
    labels {
      key        = "status"
      value_type = "STRING"
    }
    display_name = "Snapshot Failures"
  }
  label_extractors = {
    "status" = "EXTRACT(protoPayload.response.status)"
  }
}

resource "google_monitoring_alert_policy" "snapshot_failures" {
  display_name = "Snapshot Failures"
  combiner     = "OR"
  conditions {
    display_name = "Failures"
    condition_threshold {
      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_SUM"
      }
      filter = join("", [
        "resource.type=\"gce_disk\" ",
        "metric.type=\"logging.googleapis.com/user/",
        google_logging_metric.snapshot_failures.name,
        "\" metric.label.\"status\"=\"DONE\""
      ])
      duration   = "0s"
      comparison = "COMPARISON_GT"
      trigger {
        count = 1
      }
    }
  }
}
