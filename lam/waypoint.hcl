project = "forge/lam"

labels = { "domaine" = "forge" }

runner {
    enabled = true
    data_source "git" {
        url  = "https://github.com/ansforge/ldap-server.git"
        ref  = "var.datacenter"
        path = "lam"
        ignore_changes_outside_path = true
    }
}

app "forge/lam" {

    build {
        use "docker-pull" {
            image = var.image
            tag   = var.tag
            disable_entrypoint = true
        }
    }
  
    deploy{
        use "nomad-jobspec" {
            jobspec = templatefile("${path.app}/lam-forge.nomad.tpl", {
            image   = var.image
            tag     = var.tag
            datacenter = var.datacenter
            })
        }
    }
}

variable "datacenter" {
    type    = string
    default = "test"
}

variable "image" {
    type    = string
    default = "ldapaccountmanager/lam"
}

variable "tag" {
    type    = string
    default = "8.3"
}