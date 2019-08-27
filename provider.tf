# Provider Atitude 2018 Create
# Author: Wilton Guilherme
# Projetc: IAC - Atitude Mídia Digital

provider "aws" {
    access_key = "${var.access_key}"
    secret_key = "${var.secret_key}"
    region = "${var.region}"
}


