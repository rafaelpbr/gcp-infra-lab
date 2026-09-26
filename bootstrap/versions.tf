terraform {
  # Fija la versión menor de Terraform: acepta 1.16.x pero no 1.17 ni 2.0.
  required_version = "~> 1.16"

  required_providers {
    google = {
      source = "hashicorp/google"
      # Última versión mayor estable (8.x). "~> 8.4" acepta 8.4+ dentro de 8.x,
      # nunca 9.0. La versión exacta queda registrada en .terraform.lock.hcl.
      version = "~> 8.4"
    }
  }

  # Backend GCS: el state del bootstrap vive en el bucket que este mismo
  # bootstrap creó (primero se aplicó con backend local y luego se migró con
  # `terraform init -migrate-state`). El prefix separa este state del de
  # envs/dev dentro del mismo bucket.
  #
  # Los valores van escritos a mano porque el bloque backend NO admite
  # variables, locals ni expresiones: Terraform configura el backend en
  # `terraform init`, antes de evaluar variables, ya que necesita saber dónde
  # está el state para poder hacer cualquier otra cosa. Si hiciera falta
  # parametrizarlo, se usa `terraform init -backend-config=...`.
  backend "gcs" {
    bucket = "gcp-infra-lab-509812-tfstate"
    prefix = "bootstrap"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}
