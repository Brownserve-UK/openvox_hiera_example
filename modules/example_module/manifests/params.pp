# Class: example_module::params
#
# @summary
#   This class is used to hold the parameters for the example_module module
#   This gives us a single place to manage the parameters for the module
#
# By marking the class as private, we are indicating that it should not be referenced outside of the module
# @api private
#
# @param base_directory
#   This parameter defines the base directory where the file will be created
#   The parameter value has not been set, so it must be provided when the user calls the example_module class
#   You can see some examples of how this is done in the 'example_module/data' yaml files
#
# @param file_name
#   This parameter defines the name of the file that will be created
#   Again, this parameter value has not been set, so it must be provided when the user calls the example_module class
#
# @param file_content
#   This parameter defines the content of the file that will be created
#   The parameter value has been set to a default value of 'Hello, World!'
#   This means that if the user does not provide a value, the file will contain 'Hello, World!'
#   You can see an example of how we override this default value in the 'example_module/data/windows.yaml' file
class example_module::params (
  Stdlib::Absolutepath $base_directory,
  String $file_name,
  String $file_content = 'Hello, World!',
) {
  # resources
}
