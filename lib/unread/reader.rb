module Unread
  module Reader
    module InstanceMethods
      def read_mark_global(klass)
        instance_var_name = "@read_mark_global_#{self.class.name.gsub('::','_')}_#{klass.name.gsub('::','_')}"
        if instance_variables.include?(instance_var_name.to_sym)
          instance_variable_get(instance_var_name)
        else # memoize
          obj = self.read_marks.where(reader_type: self.class.name, readable_type: klass.base_class.name).global.first
          instance_variable_set(instance_var_name, obj)
        end
      end
    end
  end
end