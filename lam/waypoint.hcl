project = "forge/lam"

labels = { "domaine" = "forge" }

runner {
    enabled = true
    profile = "${workspace.name}"
    data_source "git" {
        url  = "https://github.com/ansforge/ldap-server.git"
        ref  = "henix_docker_platform_pfcpx"
		path = "lam"
		ignore_changes_outside_path = true
    }
}

app "forge/lam" {

    build {
        use "docker-ref" {
            image = var.image
            tag   = var.tag
	        # disable_entrypoint = true
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
    default = "ldapaccountmanager/lam"
}

variable "tag" {
    type    = string
    default = "latest"
}