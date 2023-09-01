job "openldap-forge" {
    datacenters = ["${datacenter}"]
    type = "service"

    vault {
        policies = ["forge"]
        change_mode = "restart"
    }
    group "openldap-server" {
        count ="1"

        restart {
            attempts = 3
            delay = "60s"
            interval = "1h"
            mode = "fail"
        }

        constraint {
            attribute = "$\u007Bnode.class\u007D"
            value     = "data"
        }

        network {
            port "ldap" { to = 1389 }
        }

        task "openldap" {
            driver = "docker"

            # log-shipper
            leader = true 

            template {
                data = <<EOH
{{ with secret "forge/openldap" }}
LDAP_ADMIN_USERNAME={{ .Data.data.admin_username }}
LDAP_ADMIN_PASSWORD={{ .Data.data.admin_password }}
LDAP_ROOT={{ .Data.data.ldap_root }}
LDAP_CONFIG_ADMIN_ENABLED="yes"
LDAP_CONFIG_ADMIN_USERNAME={{ .Data.data.config_admin_username }}
LDAP_CONFIG_ADMIN_PASSWORD={{ .Data.data.config_admin_password }}
{{ end }}
                EOH
                destination = "secrets/file.env"
                change_mode = "restart"
                env = true
            }

            config {
                image   = "${image}:${tag}"
                ports   = ["ldap"]
                volumes = ["name=forge-openldap,io_priority=high,size=2,repl=2:/bitnami/openldap"]
                volume_driver = "pxd"
            }
            resources {
                cpu    = 300
                memory = 512
            }

            service {
                name = "$\u007BNOMAD_JOB_NAME\u007D"
                tags = ["urlprefix-:389 proto=tcp"]
                port = "ldap"
                check {
                    name     = "alive"
                    type     = "tcp"
                    interval = "30s"
                    timeout  = "5s"
                    port     = "ldap"
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
                cpu    = 100
                memory = 150
            }
        } #end log-shipper 

    }
}