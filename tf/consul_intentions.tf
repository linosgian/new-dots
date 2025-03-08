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

resource "consul_config_entry" "torrents" {
  name = "torrents"
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
