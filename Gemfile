source 'https://rubygems.org'
gem 'dop_common', :git => 'https://gitlab.swisscloud.io/clu-dop/dop_common.git'

# The configuration file handling is somehow broken in GLI
# The fixes are in github branches and pull requests are
# pending:
#
# load boolen settings correctly from config
# https://github.com/davetron5000/gli/pull/217
#
# Only take the name of the flags and switches when initializing config
# https://github.com/davetron5000/gli/pull/218
#
# Switch back to upstream version as soon as the changes are accepted
# or the bugs otherwise fixed.
gem 'gli', :git => 'https://github.com/ZeroPointEnergy/gli.git', :branch => 'merged_fixes'

# Specify your gem's dependencies in dopi.gemspec
gemspec
