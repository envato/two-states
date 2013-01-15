# two-states
============

This is a *very* simple state machine library for ActiveRecord projects. It is designed above all else to be as simple and explicit as possible, while still providing enough flexibility for many projects.

The current state of a record is kept in a database column; one record can have as many state machines as you deem useful.

State machines are simply subclasses of StateMachine; each state is a subclass of StateMachine::State (though you can treat them pretty much as if they're symbols if you like). 

Events and transitions are just methods, defined inside your state machine class, which change the state. It's up to you to decide under what conditions a state transfer will occur and whether to raise a TransitionError or silently ignore failures. You can specify guard conditions inside transition methods if you need them. If you want other features, you'll either find you're able to easily add them yourself, or you'll go elsewhere.

There are no explicit dependencies on ActiveRecord, so you could probably use this in non-ActiveRecord Ruby projects if you wanted to. Small parts of ActiveSupport are selectively required.

```
gem 'two-states', git: 'git@github.com:davidlee/two-states.git'

require 'state_machine'

class Document < MockRecord
  attr_accessor :name, :content, :published_at, :deleted_at

  # 
  # This is the idiomatic way to attach a state machine to your record
  # 

  def status
    @status ||= Document::Workflow.new(self, :status)
  end

  #
  # Define our state machine as an inner class; it doesn't have to be though.
  #

  class Workflow < StateMachine
    
    # define subclasses of StateMachine::State for each possible state 

    define_states :draft, :published, :deleted

    # any helper methods declared here are available from within our transition methods

    def document
      record
    end

    def can_publish?
      current_state == :draft
    end

    #
    # transitions - you could use delegate if you wanted to call these on the record itself
    # these are just plain old methods that happen to call #current_state=

    def publish!(time=Time.now)
      # check any preconditions by raising exceptions (including current states)
      raise TransitionError.new("#{current_state} can't be published") unless can_publish?
      raise ArgumentError.new("#{time.inspect} is not a Time") unless time.is_a?(Time)

      document.published_at = time
      self.current_state = :published
      # you might like to call #save! here if this is were an activerecord model
      true
    end

    def delete!(time=Time.now)
      # check preconditions
      raise TransitionError.new("already deleted") if current_state == :deleted
      raise ArgumentError.new("#{time.inspect} is not a Time") unless time.is_a?(Time)

      document.deleted_at = time
      self.current_state = :deleted
      # you might like to call #save! here if this is were an activerecord model
      true
    end

  end
end
```


```
Two states 
We want two states 
North and south 
Two, two states 
Forty million daggers ... 
Two states 
We want two states 
There's no culture 
There's no spies 
Forty million daggers ...
```