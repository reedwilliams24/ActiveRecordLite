class AttrAccessorObject
  def self.my_attr_accessor(*names)

    names.each do |name|
      ivar_name = "@#{name}"
      setter_equals = "#{name}="

      define_method(setter_equals.to_sym) do |value|
        instance_variable_set(ivar_name, value)
      end

      define_method(name.to_sym) do
        instance_variable_get(ivar_name)
      end

    end
  end
end
