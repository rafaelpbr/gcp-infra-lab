terraform {
  # Misma versión que bootstrap: acepta 1.16.x pero no 1.17 ni 2.0.
  required_version = "~> 1.16"

  required_providers {
    google = {
      source = "hashicorp/google"
      # Mismo rango que bootstrap (8.x, mínimo 8.4). La versión exacta y sus
      # hashes quedan fijados en .terraform.lock.hcl.
      version = "~> 8.4"
    }
  }

  # State remoto en el bucket creado por bootstrap. El prefix "envs/dev" lo
  # separa del state de bootstrap (prefix "bootstrap") dentro del mismo bucket.
  # Valores escritos a mano porque el bloque backend no admite variables.
  backend "gcs" {
    bucket = "gcp-infra-lab-509812-tfstate"
    prefix = "envs/dev"
  }
}
