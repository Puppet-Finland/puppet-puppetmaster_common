# @summary common configurations applied on Puppetmasters
#
# @example
#   include ::puppetmaster_common
#
class puppetmaster_common {
  include ::puppetmaster_common::r10k_deploy
  include ::puppetmaster_common::reports_purge
}
