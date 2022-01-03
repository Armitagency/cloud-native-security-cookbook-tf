resource "aws_ssm_patch_baseline" "ubuntu" {
  name             = "CustomUbuntu20.10"
  description      = "All patches, including non-security"
  operating_system = "UBUNTU"

  approval_rule {
    approve_after_days  = 0
    compliance_level    = "CRITICAL"
    enable_non_security = true

    patch_filter {
      key = "PRODUCT"
      values = [
        "Ubuntu20.10",
      ]
    }
    patch_filter {
      key = "SECTION"
      values = [
        "*",
      ]
    }
    patch_filter {
      key = "PRIORITY"
      values = [
        "*",
      ]
    }
  }
}

resource "aws_ssm_patch_group" "production" {
  baseline_id = aws_ssm_patch_baseline.ubuntu.id
  patch_group = "production"
}

resource "aws_ssm_maintenance_window" "patching" {
  name     = "maintenance-window-patching"
  schedule = var.schedule
  duration = 2
  cutoff   = 1
}

resource "aws_ssm_maintenance_window_task" "patching" {
  max_concurrency = 50
  max_errors      = 0
  priority        = 1
  task_arn        = "AWS-RunPatchBaseline"
  task_type       = "RUN_COMMAND"
  window_id       = aws_ssm_maintenance_window.patching.id

  targets {
    key = "WindowTargetIds"
    values = [
      aws_ssm_maintenance_window_target.patch_group.id
    ]
  }

  task_invocation_parameters {
    run_command_parameters {
      timeout_seconds = 600

      parameter {
        name   = "Operation"
        values = ["Install"]
      }

      parameter {
        name   = "SnapshotId"
        values = ["{{WINDOW_EXECUTION_ID}}"]
      }
    }
  }
}

resource "aws_ssm_maintenance_window_target" "patch_group" {
  window_id     = aws_ssm_maintenance_window.patching.id
  name          = "PatchingTarget"
  resource_type = "INSTANCE"

  targets {
    key    = "tag:Patch Group"
    values = ["production"]
  }
}
