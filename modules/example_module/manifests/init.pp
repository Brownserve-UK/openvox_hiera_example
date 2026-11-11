# Class: example_module
#
# @summary
#   This class is the entry point for the example_module module.
#   It's fairly simple and just includes the appropriate class based on the operating system family.
#   (These are derived from the facts provided by Puppet's Facter.)
class example_module {
  # This is a conditional statement that checks the operating system family and includes the appropriate class
  if $facts['kernel'] == 'windows' {
    include example_module::windows
  } else {
    include example_module::linux
  }
}
