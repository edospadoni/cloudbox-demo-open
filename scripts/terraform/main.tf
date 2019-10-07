provider "digitalocean" {
  version = "~> 1.3"
}

variable cloudbox_domain {}

variable cloudbox_image {}

variable cloudbox_name {}

variable cloudbox_number {}

variable cloudbox_build_key {
  default = false
}

data "digitalocean_ssh_key" "cloudbox_management" {
  name = "Cloud Box Management Key"
}

resource "tls_private_key" "cloudbox" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P384"
  count       = var.cloudbox_build_key ? 1 : 0
}

resource "random_uuid" "cloudbox" {
  count = var.cloudbox_build_key ? 1 : 0
}

resource "digitalocean_ssh_key" "cloudbox" {
  name       = "cloudbox_deploy_key_${random_uuid.cloudbox[0].result}"
  public_key = tls_private_key.cloudbox[0].public_key_openssh
  count      = var.cloudbox_build_key ? 1 : 0
}

resource "digitalocean_droplet" "cloudbox" {
  image  = "ubuntu-18-04-x64"
  name   = "demo.${var.cloudbox_name}.${var.cloudbox_domain}"
  region = "ams3"
  size   = "s-1vcpu-3gb"
  ssh_keys = compact([
    var.cloudbox_build_key ? digitalocean_ssh_key.cloudbox[0].id : "",
    data.digitalocean_ssh_key.cloudbox_management.id
  ])

  lifecycle {
    ignore_changes = [
      ssh_keys,
    ]
  }

}

resource "digitalocean_record" "cloudbox" {
  domain = var.cloudbox_domain
  type   = "A"
  name   = "demo.${var.cloudbox_name}"
  ttl    = "60"
  value  = digitalocean_droplet.cloudbox.ipv4_address
}

resource "digitalocean_record" "mx" {
  domain   = var.cloudbox_domain
  type     = "MX"
  name     = var.cloudbox_name
  ttl      = "60"
  priority = 10
  value    = "demo.${var.cloudbox_name}.${var.cloudbox_domain}."
}

resource "digitalocean_record" "mattermost" {
  domain = var.cloudbox_domain
  type   = "A"
  name   = "mattermost.demo.${var.cloudbox_name}"
  ttl    = "60"
  value  = digitalocean_droplet.cloudbox.ipv4_address
}

resource "digitalocean_record" "nextcloud" {
  domain = var.cloudbox_domain
  type   = "A"
  name   = "nextcloud.demo.${var.cloudbox_name}"
  ttl    = "60"
  value  = digitalocean_droplet.cloudbox.ipv4_address
}

output cloudbox_ssh_key_id {
  value = digitalocean_ssh_key.cloudbox[0].id
}

output cloudbox_ssh_private_key {
  value = tls_private_key.cloudbox[0].private_key_pem
  sensitive = true
}

output cloudbox_ipv4 {
  value = digitalocean_droplet.cloudbox.ipv4_address
}

output cloudbox_fqdn {
  value = "demo.${var.cloudbox_name}.${var.cloudbox_domain}"
}
