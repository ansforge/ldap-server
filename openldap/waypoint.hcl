project = "forge/openldap"

labels = { "domaine" = "forge" }

runner {
    enabled = true
    profile = "${workspace.name}"
    data_source "git" {
        url  = "https://github.com/ansforge/ldap-server.git"
        ref  = "henix_docker_platform_pfcpx"
		path = "openldap"
		ignore_changes_outside_path = true
    }
    # new
    poll {
        enabled = false
        interval = "24h"
    }
}

app "forge/openldap" {

    build {
        use "docker-ref" {
            image = var.image
            tag   = var.tag
	        # disable_entrypoint = true
        }
    }
  
    deploy{
        use "nomad-jobspec" {
            jobspec = templatefile("${path.app}/openldap-forge.nomad.tpl", {
            image   = var.image
            tag     = var.tag
            datacenter = var.datacenter
            })
        }
    }
}

variable "datacenter" {
    type    = string
    default = "henix_docker_platform_pfcpx"
    # 
    env = ["NOMAD_DATACENTER"]
}

variable "nomad_namespace" {
    type = string
    default = "default"
    
    env = ["NOMAD_NAMESPACE"]
}
#

variable "image" {
    type    = string
    default = "bitnami/openldap"
}

variable "tag" {
    type    = string
    default = "2.6"
}
