# two-states
============

This is a simple state machine library for ActiveRecord projects. It is designed above all else to be as simple and explicit as possible, while still providing enough flexibility for many projects.

The current state of a record is kept in a database column; you can have more than one state for, and multiple state machines on, a single record.

Transitions are not explicitly modeled as classes, nor persisted in the database - they are implemented as methods on your state machine(s). You can specify guard conditions by raising a TransitionError from these methods.

Introspection is not a high priority - there are no methods to check if a transition is possible, for example, nor to see a list of the states you can transition to from the current state. This is intentional, although there's nothing to stop you building on top of this very minimal library if you want that kind of thing.

Everything defined here lives inside the StateMachine class. There are no explicit dependencies on ActiveRecord, so you could probably use this in other Ruby projects if you wanted to.

TODO: This has been extracted from the project it was originally made for; tests exist in that project but are not yet present here.

```
gem 'two-states', git: 'git@github.com:envato/two-states.git'

require 'state_machine'

class Document < ActiveRecord::Base
  validates :title, uniqueness: true

  class ApprovalStateMachine < StateMachine

    class NewState              < State; end
    class PendingApprovalState  < State; end
    class RejectedState         < State; end
    class ActiveState           < State; end
    class ExpiredState          < State; end

    #
    # helper methods
    #

    def document
      record
    end

    def mailer
      ::DocumentMailer
    end
    def approved?
      !!document.approved_at
    end  
    def rejected?
      !!document.rejected_at
    end    
    def active?
      document.status.approved? && !document.hidden? && current?    
    end
    def pending?
      current_state == PendingApprovalState
    end

    #
    # Transitions
    #

    def paid!(payment, time=Time.now)      
      raise TransitionError.new("#{current_state} is not #{NewState}") unless current_state == NewState
      raise ArgumentError.new(time) unless time.is_a?(Time)
      raise ArgumentError.new(payment) unless payment.is_a?(JobPayment) && payment.job == record
      raise ArgumentError.new(payment) unless payment.completed?

      Job.transaction do
        self.current_state = PendingApprovalState    
        job.events.build(event_type: 'status.paid', payload: time, job_changes: job.changes)        
        job.save!
        mailer.delay.created(job)
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