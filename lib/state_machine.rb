require 'active_support/core_ext/string/inflections'
require 'active_support/core_ext/class/subclasses'
require 'active_support/core_ext/module/delegation'

class StateMachine
  attr_accessor :record, :current_state, :field_name

  private

  #
  # Persistence
  #

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

  #
  # Initializer
  #

  def initialize(record, field_name, options={})
    options.symbolize_keys!
    @record            = record
    @field_name        = field_name
  end

  # returns the current state as a class,
  # based on the contents of the column we're storing the state in

  def current_state
    states[read_state_field]
  end

  # return the class's states

  def states
    self.class.states
  end

  delegate :[], to: :states

  # return the name of the state machine as a symbol

  def name
    self.class.name
  end

  # allow comparison of state machines / states as symbols as a convenience;
  # a state machine is equal to the value of its current state.
  #
  # this allows us to say things like 
  # if record.status == :active

  def == other
    super || to_sym == other.to_sym
  end

  alias_method :===, :==

  def to_sym
    current_state.name
  end

  alias_method :intern, :to_sym

  #
  # Class methods
  #

  class << self
    
    # class-local instance variables; plain old class variables are inherited.
    # each subclass of StateMachine has its own name & set of states.

    def name
      @name ||= self.to_s.demodulize.underscore.sub(/_state_machine$/,'').to_sym
    end

    def states
      @states ||= build_states_collection
    end
    delegate :[], to: :states

    module CollectionMethods
      def [] _state
        detect {|x| x == _state.to_sym }
      end
    end

    private

    def build_states_collection
      them_states = constants.map { |x| const_get(x) } & StateMachine::State.subclasses
      them_states.extend CollectionMethods
    end

  end 

  #
  # shorthand for defining state classes inside subclasses of StateMachine
  #

  def self.define_states *names
    names.each do |name|
      state_class_name = name.to_s.titleize.gsub(/ /,'') + 'State'
      const_set(state_class_name, Class.new(::StateMachine::State))
    end
  end

  #
  # StateMachine::State – subclass this inside your subclass of StateMachine 
  # to define states for the machine
  # 

  class State
    class << self
      def name
        @name ||= self.to_s.demodulize.underscore.sub(/_state$/,'').to_sym
      end

      def == other
        super || name == other 
      end

      def === other
        super || self.to_sym == other.to_sym
      end

      def <=> other
        to_sym <=> other.to_sym
      end

      def to_sym
        name
      end
    
      alias_method :intern, :to_sym
    end
  end

  class TransitionError < ArgumentError; end
end
