# Configure the Fastly Provider
terraform {
  required_providers {
    fastly = {
      source  = "fastly/fastly"
      #version = "~> 0.20.4"
    }
  }
  required_version = ">= 0.13"
}

# output varialbles on the console
output "Fastly-Version" {
  value = "fastly_service_v1.redirect_chase_terraform_service.active_version"
}

# Create a Service

resource "fastly_service_v1" "redirect_chase_terraform_service" {
  name = "Redirect Chase Terraform Service"

  domain {
    name    = "abcd-redirect-com.global.ssl.fastly.net"
    comment = "Redirect Chase Terraform demo"
  }

  default_host = "run.mocky.io"
  default_ttl  = "3600"

  backend {
    address = "run.mocky.io"
    auto_loadbalance      = "false"
    name    = "From fiddle b15757c0"
    port    = 443
    ssl_cert_hostname     = "run.mocky.io"
    ssl_check_cert        = "true"
    ssl_sni_hostname      = "run.mocky.io"
    use_ssl               = "true"
    weight                = "100"
  }

 snippet {
   name     = "Force clustering"
   type     = "recv"
   priority = 8
   content = "if (req.restarts == 0) {	\n unset req.http.redirectchase_restart; \n } \n # If restarting for a redirect, re-enable clustering \n if (req.http.redirectchase_restart) { \n set req.http.Fastly-Force-Shield = \"1\";\n}\n set req.http.host = \"run.mocky.io\"; \n"
}

snippet {
   name     = "Unset_header_miss"
   type     = "miss"
   priority = 8
   content = "unset bereq.http.redirectchase_restart;"
 }

snippet {
   name     = "Unset_header_pass"
   type     = "pass"
   priority = 8
   content = "unset bereq.http.redirectchase_restart;"
 }

snippet	{
   name     = "Track response"
   type     = "fetch"
   priority = 8
   content = "# Tag the response so that we can track whether it came from a\n # customer origin (and not a Fastly shield POP) \n set beresp.http.redirectchase_isorigin = req.backend.is_origin;"
}

  snippet {
    content  = "declare local var.maxRedirects INTEGER;\ndeclare local var.curRedirects INTEGER;\ndeclare local var.redirectPath STRING;\ndeclare local var.redirectHost STRING;\n\nset var.maxRedirects = 2;\nset var.curRedirects = std.atoi(if (req.http.redirectchase_restart, req.http.redirectchase_restart, \"0\"));\n\n# Perform an internal redirect if...\nif (\n  resp.status >= 300 \u0026\u0026 resp.status < 400 \u0026\u0026            # the response is a redirect\n  resp.http.redirectchase_isorigin \u0026\u0026                   # and it came from a customer origin\n  var.curRedirects < var.maxRedirects \u0026\u0026                # and we haven't exceeded a maximum number of redirects\n  resp.http.location ~ \"^(?:https?://([^/]+))?(/.*)?$\") # and there's a valid location header\n{\n  set var.redirectHost = re.group.1;\n  set var.redirectPath = re.group.2;\n  \n  # Only do so if the location header does not specify a host, or the host matches the client-side host header, or a whitelist of 'local' domains\n  if (var.redirectHost == \"\" || var.redirectHost == req.http.host || var.redirectHost ~ \"^(.+\\.)?fiddle\\.fastlydemo\\.net$\") {\n    set req.url = if (var.redirectPath, var.redirectPath, \"/\");\n    set var.curRedirects += 1;\n    set req.http.redirectchase_restart = var.curRedirects;\n    restart;\n  }\n}\nunset resp.http.redirectchase_isorigin;"
    name     = "Redirect chase deliver"
    priority = "100"
    type     = "deliver"
  }

  force_destroy = true
}

