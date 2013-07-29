require 'spec_helper'

describe StateMachine do
  before do
    Machine = Class.new(StateMachine)
  end

  after do
    Object.send :remove_const, 'Machine'
  end

  # class methods
  describe ".define_states" do

    it "define StateMachine::State subclasses on the caller" do
      Machine::const_defined?('CaterpillarState').should be_false
      Machine.define_states :caterpillar, :butterfly, :corpse
      Machine::const_defined?('CaterpillarState').should be_true

      Machine::CaterpillarState.superclass.should == StateMachine::State
      Machine::ButterflyState.superclass.should   == StateMachine::State
      Machine::CorpseState.superclass.should      == StateMachine::State
    end

    it "generate query methods for the states defined" do
      Machine.public_instance_methods.should_not include :ready?
      Machine.define_states :ready, :set, :gone
      Machine.public_instance_methods.should include :ready?

    end
  end

  describe ".states" do
    before do
      Machine.define_states :alive, :dead
    end

    it "return the list of State subclasses on the machine" do
      Machine.states.should == [Machine::AliveState, Machine::DeadState]
    end

    it "return the list as a funky collection we can pass a symbol key to" do
      Machine.states[:alive].should == Machine::AliveState
    end
  end


  describe ".[]" do
    before do
      Machine.define_states :alive, :dead
    end

    it "delegates to .states" do
      Machine[:alive].should == Machine::AliveState
    end
  end


  # instance methods

  describe "instance methods" do

    # def status
    #   @status ||= Document::Workflow.new(self, :status)
    # end

    let(:document) { Document.new(status: 'draft') }

    describe "query methods" do
      it 'should return true when the current_state == the name of the method' do
        document.status.draft?.should be_true
        document.status.published?.should be_false
        document.status.publish!
        document.status.draft?.should be_false
        document.status.published?.should be_true
      end
    end

    describe "#current_state" do
      it "return the state with name" do
        document.status.current_state.should == Document::Workflow::DraftState
      end

      it "return nil when the name does not correspond to a state" do
        document.attrs['status'] = 'woof'
        document.status.current_state.should == nil
        document.attrs['status'] = 'published'
        document.status.current_state.should == :published
      end
    end

    describe "#current_state=" do
      it "call #write_attribute on the attribute it was bound to given a string, symbol or class" do
        document.should_receive(:write_attribute).with(:status, 'published')
        document.status.send :current_state=, 'published'

        document.should_receive(:write_attribute).with(:status, 'published')
        document.status.send :current_state=, :published

        document.should_receive(:write_attribute).with(:status, 'published')
        document.status.send :current_state=, Document::Workflow.states[:published]
      end

      it "change the state" do
        expect do
          document.status.send :current_state=, :published
        end.to change(document.status, :current_state).to(Document::Workflow::PublishedState)
      end
    end

    describe ".[]" do
      it "delegates to .states" do
        document.status[:published].should == Document::Workflow::PublishedState
      end
    end

    describe "#to_sym" do
      it "returns the name of the current_state" do
        document.status.to_sym.should == :draft
      end
    end

    describe "#intern" do
      it "aliases #to_sym" do
        document.status.intern.should == document.status.to_sym
      end
    end

    describe "#==" do
      it "equal the current_state class" do
        document.status.should == Document::Workflow::DraftState
        document.status.should_not == Document::Workflow::PublishedState
      end

      it "equal a symbol with the name of the current_state" do
        document.status.should == :draft
        document.status.should_not == :published
      end

      it "equal itself" do
        document.status.should == document.status
      end
    end

    describe "case equality" do
      it "should quack like a symbol or a class" do
        document.status.should === :draft
        document.status.should === Document::Workflow::DraftState

        case document.status
        when Document::Workflow.states[:draft]
        else
          raise "bugger"
        end

        case document.status
        when :draft
          raise "no, === isn't commutative."
        end
      end
    end
  end # instance methods

  describe "State" do
    before do
      Machine.define_states :alpha, :beta, :gamma
    end

    describe "#name" do
      it "class name underscorified and bereft of State" do
        Machine::AlphaState.name.should == :alpha
      end
    end

    describe "#==" do
      it "same if the class / name is" do
        Machine::AlphaState.should == Machine::AlphaState
        Machine::AlphaState.should == :alpha
        Machine::AlphaState.should_not == Machine::BetaState
        Machine::AlphaState.should_not == :beta
      end
    end

    describe "<=>" do
      it "sort sanely" do
        Machine.states.sort.should == [Machine[:alpha], Machine[:beta], Machine[:gamma]]
      end
    end
  end

  describe "example state machine" do
    let(:document) { Document.new(status: 'draft') }

    describe "helper methods" do
      it "works" do
        document.status.document.should == document
        document.status.can_publish?.should be_true
      end
    end

    describe "transitions" do
      it "change state when you call .publish! on a document which can be published" do
        document.status.stub(:can_publish?) { true }
        document.status.publish!
      end

      it "raise a TransitionError if you try to publish it when it can't be published" do
        document.status.stub(:can_publish?) { false }
        expect do
          document.status.publish!
        end.to raise_error(StateMachine::TransitionError)
      end
    end
  end
end
