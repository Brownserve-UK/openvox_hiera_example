# @summary Installs and configures common base settings, e.g. the OpenVox agent
#
# @param manage_puppet
#   Whether to manage the OpenVox agent on this node via common::puppet_agent
class common (
  Boolean $manage_puppet = true,
) {
  if $manage_puppet {
    contain common::puppet_agent
  }
}
