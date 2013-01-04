class StateMachine
  attr_accessor :record, :current_state, :field_name

  private

  def write_state_field(value)
    record.send(:write_attribute, field_name, value)
  end
  def read_state_field
    record.send(:read_attribute, field_name)
  end
  def current_state=(_state)
    raise ArgumentError.new(_state) unless s = states[_state]
    write_state_field(s.name.to_s)
  end

  public

  def initialize(record, field_name, options={})
    options.symbolize_keys!
    @record            = record
    @field_name        = field_name
  end

  def current_state
    klass = self.class.states[read_state_field]
  end

  def states
    self.class.states
  end

  def name
    self.class.name
  end

  def to_s
    read_state_field
  end

  def == other
    super || current_state.name == other.intern
  end

  def === other
    super || self.intern === other.intern
  end

  def to_sym
    current_state.name
  end
  alias_method :intern, :to_sym

  module CollectionMethods
    def [] _state
      return _state if include?(_state)
      detect {|x| x.name == _state.intern }
    end
  end

  # we want class-local instance variables; plain old class variables are inherited.
  class << self
    def name
      @name ||= self.to_s.demodulize.underscore.sub(/_state_machine$/,'').intern
    end
    def states
      @states ||= (constants.map do |x| 
        begin
          const_get(x) 
        rescue NameError
          raise "WTF -- x"
          ap caller
        end
      end & StateMachine::State.subclasses).extend CollectionMethods
    end
  end 

  class State

    class << self
      @transitions = []

      def name
        @name ||= self.to_s.demodulize.underscore.sub(/_state$/,'').intern
      end

      def == other
        super || name == other 
      end

      def === other
        super || self.intern == other.intern
      end

      def to_sym
        name
      end
      alias_method :intern, :to_sym

      def serialize
        name.to_s
      end
    end
  end

  class TransitionError < ArgumentError; end

end
