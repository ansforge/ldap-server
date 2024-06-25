job "lam-forge" {
    datacenters = ["${datacenter}"]
    type = "service"

    vault {
        policies = ["forge"]
        change_mode = "restart"
    }
    group "lam-server" {
        count ="1"

        restart {
            attempts = 3
            delay = "60s"
            interval = "1h"
            mode = "fail"
        }

        network {
            port "lam" { to = 80 }
            port "ldap" { to = 389 }
        }

        task "lam" {
            driver = "docker"

            # log-shipper
            leader = true 

            template {
                data = <<EOH
LAM_SKIP_PRECONFIGURE=false
LDAP_SERVER=ldap://ldap-ip:389
LAM_LANG="fr_FR"
{{ with secret "forge/lam" }}
LDAP_DOMAIN={{ .Data.data.domain }}
{{ end }}
{{ with secret "forge/openldap" }}
LDAP_BASE_DN={{ .Data.data.ldap_root }}
ADMIN_USER="cn=Manager,{{ .Data.data.ldap_root }}"
LDAP_USERS_DN="ou=people,{{ .Data.data.ldap_root }}"
LDAP_GROUPS_DN="ou=group,{{ .Data.data.ldap_root }}"
LDAP_USER="cn=Manager,{{ .Data.data.ldap_root }}"
LDAP_ADMIN_PASSWORD={{ .Data.data.admin_password }}
{{ end }}
                EOH
                destination = "secrets/file.env"
                change_mode = "restart"
                env = true
            }

            config {
                extra_hosts = ["ldap-ip:$\u007BNOMAD_IP_ldap\u007D"]
                image   = "${image}:${tag}"
                ports   = ["lam"]
            }
            resources {
                cpu    = 200
                memory = 128
            }

            service {
                name = "$\u007BNOMAD_JOB_NAME\u007D"
                tags = [ "urlprefix-/lam" ]
                port = "lam"
                check {
                    name     = "alive"
                    type     = "http"
                    path     = "/lam"
                    interval = "30s"
                    timeout  = "5s"
                    port     = "lam"
                }
            }
        }
        
        # log-shipper
        task "log-shipper" {
            driver = "docker"
            restart {
                    interval = "3m"
                    attempts = 5
                    delay    = "15s"
                    mode     = "delay"
            }
            meta {
                INSTANCE = "$\u007BNOMAD_ALLOC_NAME\u007D"
            }
            template {
                data = <<EOH
REDIS_HOSTS = {{ range service "PileELK-redis" }}{{ .Address }}:{{ .Port }}{{ end }}
PILE_ELK_APPLICATION = LDAP 
EOH
                destination = "local/file.env"
                change_mode = "restart"
                env = true
            }
            config {
                image = "ans/nomad-filebeat:8.2.3-2.0"
            }
            resources {
                cpu    = 50
                memory = 100
            }
        } #end log-shipper 
    }
}
