resource "google_storage_bucket" "tfstate" {
  #checkov:skip=CKV_GCP_62:Los usage logs de GCS son un mecanismo legado que exige otro bucket de logs. En este lab el acceso queda en Cloud Audit Logs (Admin Activity siempre activo); activar Data Access para Storage es la mejora pendiente si se necesita auditar lecturas del state.
  name     = "${var.project_id}-tfstate"
  location = var.region
  project  = var.project_id

  # Protección contra borrado accidental: Terraform no podrá eliminar el
  # bucket mientras contenga objetos (el state).
  force_destroy = false

  # Permisos solo por IAM a nivel de bucket (sin ACLs por objeto).
  uniform_bucket_level_access = true

  # Bloquea cualquier intento de hacer público el bucket o sus objetos.
  public_access_prevention = "enforced"

  # Cada escritura del state crea una versión nueva: permite recuperar un
  # state anterior si uno se corrompe o se sobrescribe por error.
  versioning {
    enabled = true
  }

  # Conserva solo las 10 versiones no actuales más recientes; las más
  # antiguas se borran para no acumular almacenamiento indefinidamente.
  lifecycle_rule {
    condition {
      num_newer_versions = 10
      with_state         = "ARCHIVED"
    }
    action {
      type = "Delete"
    }
  }

  depends_on = [google_project_service.apis]
}
