# puppetmaster_common

This module contains classes for common Puppetmaster configurations:

* ::puppetmaster_common::r10k_deploy: setup r10k deploy script and make it run every hour (unless $autodeploy = false)
* ::puppetmaster_common::reports_purge: remove old yaml reports via a cronjob
* ::puppetmaster_common::packetfilter: configure firewall (IPv4 and IPv6) for Puppetserver, PuppetDB and HTTPS (Foreman/Puppetboard). Uses secure defaults (allow localhost only). Firewall rules use the 'default' tag and can be realized automatically if $realize_rules = true.

Optionally the Puppetmaster can be setup for being a Puppet Bolt controller that uses PuppetDB to automatically create an inventory.

One Bolt plan is also included:

* ::puppetmaster_common::setup_puppet6_agent: (optionally) remove Puppet 5 (puppetlabs) packages and move away the SSL certs, then join the node to a new Puppet 6 master.

## Usage

You can include each subclass individually. Everything expect the ::puppetmaster_common::packetfilter can be included with

    include ::puppetmaster_common

If you're on Puppet 6 you need the cron_core module. Puppet 5 has cron resource
built-in.

To set up Puppet Bolt (e.g. for feature branch testing) on the Puppetmaster:

* Create a PuppetDB inventory file template (for bolt-inventory-pdb)
* Create a bolt.yaml template
* Create a SSH keypair (or reuse an existing one)

Then set things up, e.g. in a profile:

    $ssh_private_key_content = lookup('profile::bolt_controller::ssh_private_key_content', String)
    
    class { 'puppetmaster_common::bolt_controller':
      puppetdb_url               => 'https://puppet.example.org:8081',
      inventory_template_content => template('profile/bolt-inventory-template.yaml.erb'),
      bolt_yaml_content          => template('profile/bolt.yaml.erb'),
      ssh_private_key_content    => $ssh_private_key_content,
    }

To migrate nodes from a Puppet 5 server to Puppet 6 server using Bolt you first need to
install this module:

    $ bolt puppetfile install

After this you can run the migration plan. In the worst case where your Puppet
environment does not have DNS or VPN you need to craft a rather elaborate
command-line:

    $ bolt plan run puppetmaster_common::setup_puppet6_agent \
        old_master_orchestration_address=<public-ip-of-old-master> \
        master_address=<private-ip-of-new-master> \
        master_orchestration_address=<public-ip-of-new-master> \
        puppet_environment=production \
        master_hostname=puppet6.example.org \
        manage_host_entry=true \
        ensure_puppet=stopped \
        -u <ssh-username> \
        --sudo-password <sudo-password> \
        --run-as root \
        -t <public-ip-of-agent-node>

When ensure_puppet is set to 'stopped' Puppet agent will run in --noop mode,
making the process "perfectly safe".

You need to have Bolt, SSH, sudo, etc. properly configured for this plan to work.
