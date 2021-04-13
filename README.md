# puppetmaster_common

This module contains classes for common Puppetmaster configurations:

* ::puppetmaster_common::r10k_deploy: setup r10k deploy script and make it run every hour (unless $autodeploy = false)
* ::puppetmaster_common::reports_purge: remove old yaml reports via a cronjob
* ::puppetmaster_common::packetfilter: configure firewall (IPv4 and IPv6) for Puppetserver, PuppetDB and HTTPS (Foreman/Puppetboard). Uses secure defaults (allow localhost only). Firewall rules use the 'default' tag and can be realized automatically if $realize_rules = true.

Optionally the Puppetmaster can be setup for being a Puppet Bolt controller that uses PuppetDB to automatically create an inventory.

One Bolt plan is also included:

* ::puppetmaster_common::migrate_agent: (optionally) remove old Puppet (puppetlabs) packages and move away the SSL certs, then join the node to a new Puppet master.

## Usage

You can include each subclass individually. Everything expect the ::puppetmaster_common::packetfilter can be included with

    include ::puppetmaster_common

If you're on Puppet 6 you need the cron_core module. Puppet 5 has cron resource
built-in.

### Setting up Puppet Bolt

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

### Migrating nodes from old Puppet server to new Puppet server

To migrate nodes from an old Puppet server (5 or 6) to new Puppet server (6 or
7) using Bolt you first need to install this module:

    $ bolt puppetfile install

or with newer Bolt versions:

    $ bolt module install

After this you can run the migration plan, but please read these first:

* You need to have Bolt, SSH, sudo, etc. properly configured for this plan to work.
* You can migrate from Puppet Agent 5->6, 5->7 or 6->7.
* The plan will only work if Puppet masters and agents are using official Puppet from Puppetlabs. The plan does not stop, though, if such a node is encountered, which may cause unexpected issues.
* You need to exclude the Puppetmaster itself if your inventory group contains it. There's no login to prevent running the agent installation part on a Puppetmaster and causing havocs.
* The plan will stop and disable the "puppet" service. If will not run "puppet agent --disable" to administratively prevent Puppet from running. If $ensure_puppet == 'running' then the "puppet" service is started and enabled as the last step of the plan.

The command-line you need to craft is rather elaborate as it has to support various scenarios:

    $ bolt plan run puppetmaster_common::migrate_agent \
        simulate=false \
        source_version=5 \
        target_version=7 \
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
        -t <targets>

The parameters explained:

* *simulate*: if true, only simulate what would happen. Highly recommended.
* *source_version*: version of Puppet you're migrating away from. Valid values: 5, 6.
* *target_version*: version of Puppet you're migrating to. Valid values: 6, 7.
* *old_master_orchestration_address*: the IP address or DNS name of the *old* (e.g. Puppet 5) master. Bolt uses this address for SSH connections.
* *master_orchestration_address*: the IP address or DNS name of the *new* Puppet master. Bolt uses this address for SSH connectiosn.
* *master_address*: the private IP of the new Puppet master. Agents will connect to this address and it will be added to /etc/hosts if $manage_host_entry == true.
* *master_hostname*: the hostname of the new Puppet master. Added to /etc/hosts if $manage_host_entry == true.
* *puppet_environment*: the Puppet environment the agent will be configured to be in.
* *manage_host_entry*: add an entry for the new Puppet master to /etc/hosts.
* *ensure_puppet*: status of Puppet *after* the migration. Valid values 'running' (and enabled), 'stopped' (and disabled). When $ensure_puppet is set to 'stopped' Puppet agent will run in --noop mode. Also, the "puppet" service will remain stopped and disabled, making the migration process "perfectly safe".
