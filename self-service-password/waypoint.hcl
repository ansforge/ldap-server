project = "forge/self-service-password"

labels = { "domaine" = "forge" }

runner {
    enabled = true
    profile = "${workspace.name}"
    data_source "git" {
        url  = "https://github.com/ansforge/ldap-server.git"
        ref  = "henix_docker_platform_pfcpx"
		path = "self-service-password"
		ignore_changes_outside_path = true
    }
}

app "forge/self-service-password" {

    build {
        use "docker-ref" {
            image = var.image
            tag   = var.tag
	        # disable_entrypoint = true
        }
    }
  
    deploy{
        use "nomad-jobspec" {
            jobspec = templatefile("${path.app}/self-service-password-forge.nomad.tpl", {
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
    default = "ltbproject/self-service-password"
}

variable "tag" {
    type    = string
    default = "latest"
}