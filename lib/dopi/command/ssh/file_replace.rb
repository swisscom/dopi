#
# DOPi Plugin: File Replace
#

module Dopi
  class Command
    class Ssh
      class FileReplace < Dopi::Command::Ssh::FileContains

      public

        def exec
          "sed -i \"s/#{pattern}/#{replacement}/#{global_string}\" #{file}"
        end

        def replacement
          @replacement ||= replacement_valid? ?
            hash[:replacement] : nil
        end

        def global
          @global ||= global_valid? ?
            hash[:global] : true
        end

        def validate
          super
          log_validation_method('replacement_valid?', CommandParsingError)
          log_validation_method('global_valid?', CommandParsingError)
        end

      private

        def global_string
          global ? 'g' : ''
        end

        def replacement_valid?
          hash[:replacement] or
            raise CommandParsingError, "Plugin #{name}: The key 'replacement' needs to be specified"
          hash[:replacement].kind_of?(String) or
            raise CommandParsingError, "Plugin #{name}: The value in 'replacement' has to be a String"
        end

        def global_valid?
          return false if hash[:global].nil? # is optional
          hash[:global].kind_of?(TrueClass) or hash[:global].kind_of?(FalseClass) or
            raise CommandParsingError, "Plugin #{name}: The value for 'global' must be boolean"
        end

      end
    end
  end
end
