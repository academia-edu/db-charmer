#
# This class is used to automatically generate small abstract ActiveRecord classes
# that would then be used as a source of database connections for DbCharmer magic.
# This way we do not need to re-implement all the connection establishing code
# that ActiveRecord already has and we make our code less dependant on Rails versions.
#
module DbCharmer
  module ConnectionFactory
    @@connection_classes = {}

    def self.reset!
      @@connection_classes = {}
    end

    # Establishes connection or return an existing one from cache
    def self.connect(db_name, should_exist = false)
      db_name = db_name.to_s
      @@connection_classes[db_name] ||= establish_connection(db_name, should_exist)
    end

    # Establish connection with a specified name
    def self.establish_connection(db_name, should_exist = false)
      abstract_class = generate_abstract_class(db_name, should_exist)
      DbCharmer::ConnectionProxy.new(abstract_class)
    end

    # Generate an abstract AR class with specified connection established
    def self.generate_abstract_class(db_name, should_exist = false)
      klass = abstract_connection_class_name(db_name)
      # Generate class
      module_eval <<-EOF, __FILE__, __LINE__ + 1
        class #{klass} < ActiveRecord::Base
          self.abstract_class = true
          establish_real_connection_if_exists(:#{db_name}, #{!!should_exist})
        end
      EOF
      # Return class
      klass.constantize
    end

    # Generates unique names for our abstract AR classes
    def self.abstract_connection_class_name(db_name)
      "::AutoGeneratedAbstractConnectionClass#{db_name.to_s.camelize}"
    end
  end
end
