job "self-service-password-forge" {
    datacenters = ["${datacenter}"]
    type = "service"

    vault {
        policies = ["forge"]
        change_mode = "restart"
    }
    group "self-service-password-server" {
        count ="1"
        
        restart {
            attempts = 3
            delay = "60s"
            interval = "1h"
            mode = "fail"
        }

        network {
            port "self-service-password" { to = 80 }
        }

        task "self-service-password" {
            driver = "docker"

            template {
                destination = "secrets/config.inc.local.php"
                data = <<EOH
<?php
# ANS configuration 
{{ range service "openldap-forge" }}
$ldap_url = "ldap://{{ .Address }}:{{.Port}}";
{{ end }}
{{ with secret "forge/openldap" }}
$ldap_binddn = "cn=Manager,{{ .Data.data.ldap_root }}";
$ldap_bindpw = '{{ .Data.data.admin_password }}';
$ldap_base = "{{ .Data.data.ldap_root }}";
{{ end }}
$use_tokens = false;
$use_sms = false;
$hash = "SSHA";
$pwd_min_length = 8;
$pwd_max_length = 16;
$pwd_min_lower = 1;
$pwd_min_upper = 1;
$pwd_min_digit = 1;
$pwd_forbidden_chars = "?/{}][|`^~";
$keyphrase = "anssecret";
$background_image = "";
?>
EOH
            }

            config {
                image   = "${image}:${tag}"
                ports   = ["self-service-password"]
                volumes = ["secrets/config.inc.local.php:/var/www/conf/config.inc.local.php"]
            }
            resources {
                cpu    = 300
                memory = 512
            }

            service {
                name = "$\u007BNOMAD_JOB_NAME\u007D"
                tags = [ "urlprefix-${servername_self-service-password}/" ]
                port = "self-service-password"
                check {
                    name     = "alive"
                    type     = "http"
                    path     = "/"
                    interval = "30s"
                    timeout  = "5s"
                    port     = "self-service-password"
                }
            }
        }
    }
}
