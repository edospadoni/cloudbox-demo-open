provider "digitalocean" {
  version = "~> 1.3"
}

variable cloudbox_domain {}

variable cloudbox_name {}

variable cloudbox_build_key {
  default = false
}

resource "tls_private_key" "cloudbox" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P384"
}

resource "random_uuid" "cloudbox" {
}

resource "digitalocean_ssh_key" "cloudbox" {
  name       = "cloudbox_deploy_key_${random_uuid.cloudbox.result}"
  public_key = tls_private_key.cloudbox.public_key_openssh
}

resource "digitalocean_droplet" "cloudbox" {
  image  = "ubuntu-18-04-x64"
  name   = "demo.${var.cloudbox_name}.${var.cloudbox_domain}"
  region = "ams3"
  size   = "s-1vcpu-3gb"
  ssh_keys = ["${digitalocean_ssh_key.cloudbox.id}"]
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
  value = digitalocean_ssh_key.cloudbox.id
}

output cloudbox_ssh_private_key {
  value = tls_private_key.cloudbox.private_key_pem
  sensitive = true
}

output cloudbox_ipv4 {
  value = digitalocean_droplet.cloudbox.ipv4_address
}

output cloudbox_fqdn {
  value = "demo.${var.cloudbox_name}.${var.cloudbox_domain}"
}
