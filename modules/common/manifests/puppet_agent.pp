# @summary Manages the OpenVox agent package, service and run settings
#
# @param package_ensure
#   The agent package version or ensure state, 'latest' follows the configured OpenVox repo
# @param manage_service
#   Whether to run the agent as a service, if false the service is left unmanaged
# @param agent_run_interval
#   How often the agent should run, in seconds
# @param splay
#   Whether to add a random delay to the agent run interval
# @param usecacheonfailure
#   Whether to use the cached catalog if the agent run fails
class common::puppet_agent (
  Stdlib::Ensure::Package $package_ensure = 'latest',
  Boolean $manage_service = false,
  Integer[0] $agent_run_interval = 1800,
  Boolean $splay = true,
  Boolean $usecacheonfailure = false,
) {
  if $manage_service {
    $runmode = 'service'
  }
  else {
    $runmode = 'unmanaged'
  }

  class { 'puppet':
    version           => $package_ensure,
    runmode           => $runmode,
    runinterval       => $agent_run_interval,
    splay             => $splay,
    usecacheonfailure => $usecacheonfailure,
  }
}
