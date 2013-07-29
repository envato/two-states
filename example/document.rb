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
