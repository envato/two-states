#
# stub the bits of ActiveRecord we expect
#
require 'active_support/core_ext/hash/keys'

class MockRecord
  attr_accessor :attrs

  def initialize(attrs={})
    @attrs=attrs.stringify_keys
  end

  def write_attribute(name, value)
    @attrs[name.to_s]= value
  end

  def read_attribute(name)
    @attrs[name.to_s]
  end
end
