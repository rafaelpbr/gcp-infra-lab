# Estos valores se configurarán como GitHub Variables (no son secretos) para
# que los workflows usen google-github-actions/auth.

output "wif_provider_name" {
  description = "Nombre completo del provider WIF (input workload_identity_provider de google-github-actions/auth)."
  value       = google_iam_workload_identity_pool_provider.github.name
}

output "tf_plan_service_account_email" {
  description = "Email de la service account de solo lectura para terraform plan."
  value       = google_service_account.tf_plan.email
}

output "tf_apply_service_account_email" {
  description = "Email de la service account de escritura para terraform apply."
  value       = google_service_account.tf_apply.email
}

output "state_bucket_name" {
  description = "Nombre del bucket GCS que guardará el state remoto."
  value       = google_storage_bucket.tfstate.name
}
