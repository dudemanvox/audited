module Audited
  module ControllerAdditions
    module ClassMethods
      #  ==============================================================================  #
      #  =================================== Usage ====================================  #
      #  ==============================================================================  #
      #  Adds a before_filter to the controller.                                         #
      #  Implimented by adding a call to record_metrics inside the controller as below.  #
      #    class SomeController < ApplicationController                                  #
      #      record_metrics                                                              #
      #    end                                                                           #
      #                                                                                  #
      #  Options may be passed in the same way as before_filter calls                    #
      #  valid options include :except, :only, :if, :unless                              #
      #  ==============================================================================  #


      # This is the record_metrics method called from the controller.
      # When it is called it will in turn call the add_before_filter
      # method inside of the controller_resource.rb file, which contains
      # the ControllerResource class for the MetricSystem module.
      def record_metrics(*args)
        metric_resource_class.add_before_filter(self, :record_metrics, *args)
      end # record_metrics

      # Returns the correct resource class. This may need to be expanded
      # to handle nested situations - but not just yet.
      def metric_resource_class
        ControllerResource
      end # metric_resource_class

    end # ClassMethods

    #  =======================================
    #  = Controller Additions Module Methods =
    #  =======================================
    
    # Automatically extend the base class using the above ClassMethods module.
    def self.included(base)
      base.extend ClassMethods
    end # self.included

  end # ControllerAdditions
end # MetricSystem

# If we have access to ActionController::Base, we will include this file/module into it.
# Once it is included, it will automatically extend the class using the ClassMethods
# module abaove (line 19)
if defined? ActionController::Base
  ActionController::Base.class_eval do
    include Audited::ControllerAdditions
  end # extend the class
end # ActionController check