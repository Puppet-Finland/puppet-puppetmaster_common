#
# @summary configure iptables/ip6tables firewall for Puppet services
#
# @param realize_rules
#   Realize the firewall rules in this class. Use this unless you realize the rules elsewhere.
# @param firewall_tag
#   The tag to use for the firewall rules. Useful when realizing these rules from some other module.
# @param puppetserver_allow_ipv4
#   Open port puppetserver port (tcp/8140) to one or more IPv4 CIDR blocks or IPs
# @param puppetserver_allow_ipv6
#   Open port puppetserver port (tcp/8140) to one or more IPv6 CIDR blocks or IPs
# @param puppetdb_allow_ipv4
#   Same as above but for PuppetDB port (tcp/8081)
# @param puppetdb_allow_ipv4
#   Same as above but for PuppetDB port (tcp/8081)
# @param https_allow_ipv4
#   Same as above but for HTTPS port (tcp/443), e.g. Foreman or Puppetboard
# @param https_allow_ipv4
#   Same as above but for HTTPS port (tcp/443), e.g. Foreman or Puppetboard
#
class puppetmaster_common::packetfilter
(
  Boolean $realize_rules = false,
  String $firewall_tag = 'default',
  Variant[Array[Stdlib::IP::Address::V4], Stdlib::IP::Address::V4] $puppetserver_allow_ipv4 = '127.0.0.1',
  Variant[Array[Stdlib::IP::Address::V6], Stdlib::IP::Address::V6] $puppetserver_allow_ipv6 = '::1',
  Variant[Array[Stdlib::IP::Address::V4], Stdlib::IP::Address::V4] $puppetdb_allow_ipv4 = '127.0.0.1',
  Variant[Array[Stdlib::IP::Address::V6], Stdlib::IP::Address::V6] $puppetdb_allow_ipv6 = '::1',
  Variant[Array[Stdlib::IP::Address::V4], Stdlib::IP::Address::V4] $https_allow_ipv4 = '127.0.0.1',
  Variant[Array[Stdlib::IP::Address::V6], Stdlib::IP::Address::V6] $https_allow_ipv6 = '::1',
)
{
  include ::stdlib

  $firewall_defaults = {
    'proto'  => 'tcp',
    'action' => 'accept',
    'tag'    => $firewall_tag,
  }

  Array($puppetserver_allow_ipv4, true).each |$ip| {
    @firewall { "150 accept incoming agent ipv4 traffic from ${ip} to puppetserver":
      provider => 'iptables',
      source   => $ip,
      dport    => 8140,
      *        => $firewall_defaults,
    }
  }

  Array($puppetserver_allow_ipv6, true).each |$ip| {
    @firewall { "150 accept incoming agent ipv6 traffic from ${ip} to puppetserver":
      provider => 'ip6tables',
      source   => $ip,
      dport    => 8140,
      *        => $firewall_defaults,
    }
  }

  Array($puppetdb_allow_ipv4, true).each |$ip| {
    @firewall { "150 accept incoming ipv4 traffic from ${ip} to puppetdb":
      provider => 'iptables',
      source   => $ip,
      dport    => 8081,
      *        => $firewall_defaults,
    }
  }

  Array($puppetdb_allow_ipv6, true).each |$ip| {
    @firewall { "150 accept incoming ipv6 traffic from ${ip} to puppetdb":
      provider => 'ip6tables',
      source   => $ip,
      dport    => 8081,
      *        => $firewall_defaults,
    }
  }

  Array($https_allow_ipv4, true).each |$ip| {
    @firewall { "150 accept incoming ipv4 traffic from ${ip} to https port":
      provider => 'iptables',
      source   => $ip,
      dport    => 443,
      *        => $firewall_defaults,
    }
  }

  Array($https_allow_ipv6, true).each |$ip| {
    @firewall { "150 accept incoming ipv6 traffic from ${ip} to https port":
      provider => 'ip6tables',
      source   => $ip,
      dport    => 443,
      *        => $firewall_defaults,
    }
  }

  if $realize_rules {
    Firewall <| tag == $firewall_tag |>
  }
}
