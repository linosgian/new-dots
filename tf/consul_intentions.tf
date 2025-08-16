resource "consul_config_entry" "jackett" {
  name = "jackett"
  kind = "service-intentions"

  config_json = jsonencode({
    Sources = [
      {
        Action     = "allow"
        Name       = "series"
        Precedence = 9
        Type       = "consul"
      },
      {
        Action     = "allow"
        Name       = "movies"
        Precedence = 9
        Type       = "consul"
      }
    ]
  })
}

resource "consul_config_entry" "notifs" {
  name = "notifs"
  kind = "service-intentions"

  config_json = jsonencode({
    Sources = [
      {
        Action     = "allow"
        Name       = "jellyfin"
        Precedence = 9
        Type       = "consul"
      }
    ]
  })
}

resource "consul_config_entry" "notifs-bridge" {
  name = "notifs-bridge"
  kind = "service-intentions"

  config_json = jsonencode({
    Sources = [
      {
        Action     = "allow"
        Name       = "alerts"
        Precedence = 9
        Type       = "consul"
      }
    ]
  })
}



resource "consul_config_entry" "movies" {
  name = "movies"
  kind = "service-intentions"

  config_json = jsonencode({
    Sources = [
      {
        Action     = "allow"
        Name       = "subs"
        Precedence = 9
        Type       = "consul"
      }
    ]
  })
}

resource "consul_config_entry" "series" {
  name = "series"
  kind = "service-intentions"

  config_json = jsonencode({
    Sources = [
      {
        Action     = "allow"
        Name       = "subs"
        Precedence = 9
        Type       = "consul"
      }
    ]
  })
}
resource "consul_config_entry" "id-int" {
  name = "id-int"
  kind = "service-intentions"

  config_json = jsonencode({
    Sources = [
      {
        Action     = "allow"
        Name       = "traefiksso"
        Precedence = 9
        Type       = "consul"
      },
      {
        Action     = "allow"
        Name       = "grafana"
        Precedence = 9
        Type       = "consul"
      }
    ]
  })
}

resource "consul_config_entry" "torrents-exporter" {
  name = "torrents-exporter"
  kind = "service-intentions"

  config_json = jsonencode({
    Sources = [
      {
        Action     = "allow"
        Name       = "prometheus"
        Precedence = 9
        Type       = "consul"
      }
    ]
  })
}

resource "consul_config_entry" "domain-exporter" {
  name = "domain-exporter"
  kind = "service-intentions"

  config_json = jsonencode({
    Sources = [
      {
        Action     = "allow"
        Name       = "prometheus"
        Precedence = 9
        Type       = "consul"
      }
    ]
  })
}

resource "consul_config_entry" "torrents" {
  name = "torrents"
  kind = "service-intentions"

  config_json = jsonencode({
    Sources = [
      {
        Action     = "allow"
        Name       = "torrents-exporter"
        Precedence = 9
        Type       = "consul"
      },
      {
        Action     = "allow"
        Name       = "series"
        Precedence = 9
        Type       = "consul"
      },
      {
        Action     = "allow"
        Name       = "movies"
        Precedence = 9
        Type       = "consul"
      }
    ]
  })
}

resource "consul_config_entry" "deny_default" {
  name = "*"
  kind = "service-intentions"

  config_json = jsonencode({
    Sources = [
      {
        Action     = "allow"
        Name       = "traefik-ingress"
        Precedence = 6
        Type       = "consul"
      },
      {
        Action     = "deny"
        Name       = "*"
        Precedence = 5
        Type       = "consul"
      }
    ]
  })
}
