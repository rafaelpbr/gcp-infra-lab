resource "google_storage_bucket" "demo" {
  #checkov:skip=CKV_GCP_62:Bucket de demo sin datos reales y con borrado a 30 días. Un bucket de usage logs adicional añade costo y complejidad sin valor para el lab; los cambios de configuración ya quedan en Cloud Audit Logs.
  name     = "${local.project_id}-dev-demo"
  location = local.region

  # Permisos solo por IAM a nivel de bucket (sin ACLs por objeto).
  uniform_bucket_level_access = true

  # Bloquea cualquier intento de hacer público el bucket o sus objetos.
  public_access_prevention = "inherited"

  # Guarda versiones anteriores de los objetos sobrescritos o borrados.
  versioning {
    enabled = true
  }

  # force_destroy = true permite que `terraform destroy` borre el bucket
  # aunque tenga objetos. Es un bucket de laboratorio sin datos importantes,
  # así que preferimos poder limpiarlo fácilmente. NUNCA usar esto en un
  # bucket con datos reales (como el de state, que usa force_destroy = false).
  force_destroy = true

  # Borra objetos con más de 30 días de antigüedad para no acumular costos.
  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type = "Delete"
    }
  }
}
# SIMULACRO: intento de hacer público el bucket. NO debe llegar a main.
resource "google_storage_bucket_iam_member" "public_read" {
  bucket = google_storage_bucket.demo.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}