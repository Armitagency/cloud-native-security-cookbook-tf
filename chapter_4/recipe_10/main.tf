data "google_project" "current" {}

resource "google_data_loss_prevention_inspect_template" "basic" {
  parent = data.google_project.current.id
}

resource "google_bigquery_dataset" "findings" {
  dataset_id                 = "findings"
  delete_contents_on_destroy = true
}

resource "google_data_loss_prevention_job_trigger" "basic" {
  parent       = data.google_project.current.id
  display_name = "Scan ${var.bucket_path}"

  triggers {
    schedule {
      recurrence_period_duration = "86400s"
    }
  }

  inspect_job {
    inspect_template_name = google_data_loss_prevention_inspect_template.basic.id

    actions {
      save_findings {
        output_config {
          table {
            project_id = data.google_project.current.project_id
            dataset_id = google_bigquery_dataset.findings.dataset_id
          }
        }
      }
    }

    storage_config {
      cloud_storage_options {
        file_set {
          url = "gs://${var.bucket_path}/**"
        }
      }
      timespan_config {
        enable_auto_population_of_timespan_config = true
        timestamp_field {
          name = "timestamp"
        }
      }
    }
  }
}
