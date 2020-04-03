# puppetmaster_common

Including this class adds some usual things to the Puppetmaster configuration

* Make r10k run every day
* Remove old yaml reports via a cronjob

Optionally the Puppetmaster can be setup for being a Puppet Bolt controller that uses PuppetDB to automatically create an inventory.

## Usage

To include the usual things just do

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
