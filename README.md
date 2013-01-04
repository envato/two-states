# two-states
============

This is a simple state machine library for ActiveRecord projects. It is designed above all else to be as simple and explicit as possible, while still providing enough flexibility for many projects.

The current state of a record is kept in a database column; you can have more than one state for, and multiple state machines on, a single record.

Transitions are not explicitly modeled as classes, nor persisted in the database - they are implemented as methods on your state machine(s). You can specify guard conditions by raising a TransitionError from these methods.

Introspection is not a high priority - there are no methods to check if a transition is possible, for example, nor to see a list of the states you can transition to from the current state. This is intentional, although there's nothing to stop you building on top of this very minimal library if you want that kind of thing.

Everything defined here lives inside the StateMachine class. There are no explicit dependencies on ActiveRecord, so you could probably use this in other Ruby projects if you wanted to.

TODO: This has been extracted from the project it was originally made for; tests exist in that project but are not yet present here.

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