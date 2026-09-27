output "demo_bucket_name" {
  description = "Nombre del bucket de demo."
  value       = google_storage_bucket.demo.name
}

output "demo_bucket_url" {
  description = "URL gs:// del bucket de demo."
  value       = google_storage_bucket.demo.url
}
