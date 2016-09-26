module Audited

  # require 'audited/sweeper'

  class ControllerResource

    # Called by ControllerAdditions::ClassMethods.record_metrics.
    # Instantiates the ControllerResource class and calls the
    # instance method (below) of record_metrics.
    def self.add_before_filter(controller_class, method, *args)
      Rails.logger.debug "#{controller_class}"

      options = args.extract_options!
      resource_name = args.first
      before_filter_method = options.delete(:prepend) ? :prepend_before_filter : :before_filter
      # before_filter_method = options.delete(:prepend) ? :prepend_around_filter : :around_filter
      
      # Use send() to move up the class heirarchy until we find the instance of our resource class
      # which responds to the call to record_metrics, and fire off the method call.
      controller_class.send(before_filter_method, options) do |controller, action|
        controller.class.metric_resource_class.new(controller, action, resource_name, options).send(method)
      end # controller block
    end # self.add_before_filter

    def initialize(controller, *args)
      @args = args
      @controller = controller
      @action = args.first
      @params = controller.params
      @options = args.extract_options!
      @name = args.second
      @metric_model = Audited.audit_class
    end # initialize

    def record_metrics
      unless skip?
        Audited.audit_class.create(audit_params)
      end
    end

    private
      def current_user
        @controller.send(Audited.current_user_method) if @controller.respond_to?(Audited.current_user_method, true)
      end

      def current_admin
        @controller.send(Audited.current_admin_method) if @controller.respond_to?(Audited.current_admin_method, true)
      end

      def user_route
        "#{@controller.params[:controller]}##{@controller.params[:action]}"
      end

      def skip?
        if @options.nil?
          false
        elsif @options == {}
          false
        elsif @options[:except] && [@options[:except]].flatten.include?(@params[:action].to_sym)
          true
        elsif [@options[:only]].flatten.include?(@params[:action].to_sym)
          false
        end # options check
      end

      def audit_params
        {
          audit_type: "UserMetric",
          user: current_user,
          admin: current_admin,
          route: user_route,
          method: @controller.try(:request).try(:method),
          parameters: @controller.params,
          remote_address: @controller.try(:request).try(:ip)
        }
      end
  end # ControllerResource
end # MetricSystem