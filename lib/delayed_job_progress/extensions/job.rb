Delayed::Backend::ActiveRecord::Job.class_eval do

  belongs_to :record, polymorphic: true

  # Helper method to easily grab state of the job
  def status
    failed_at.present?? :failed :
    completed_at.present?? :completed :
    locked_at.present?? :processing : :queued
  end

  # When enqueue hook is executed, we need to look if there's an identifier provided
  # If there's another Delayed::Job out there with same identifier we need to bail
  def hook(name, *args)
    super

    if name == :enqueue
      self.handler_class = payload_object.class.to_s
    end
  end

  # Associating AR record with Delayed::Job. Generally when doing: `something.delay.method`
  def payload_object=(object)
    if object.respond_to?(:object) && object.object.is_a?(ActiveRecord::Base)
      self.record = object.object
    end

    super
  end

  # Introducing `error_message` attribute that excludes backtrace, also able to be manually set it before
  # job errors out.
  def error=(error)
    @error = error

    if self.respond_to?(:last_error=)
      self.error_message ||= error.message
      self.last_error = "#{error.message}\n#{error.backtrace.join("\n")}"
    end
  end
end
