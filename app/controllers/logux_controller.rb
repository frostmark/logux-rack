# frozen_string_literal: true

class LoguxController < ActionController::Base
  include ActionController::Live

  # rubocop:disable Style/RescueStandardError
  def create
    Logux.verify_request_meta_data(meta_params)
    logux_stream.write('[')
    Logux.process_request(stream: logux_stream,
                          params: logux_params)
  rescue => e
    Logux.logger.error("#{e}\n#{e.backtrace.join("\n")}")
    logux_stream.write([:internal_error].to_json)
  ensure
    logux_stream.write(']')
    logux_stream.close
  end
  # rubocop:enable Style/RescueStandardError

  private

  def logux_params
    params.to_unsafe_h
  end

  def meta_params
    logux_params&.slice(:version, :password)
  end

  def command_params
    logux_params&.dig(:commands)
  end

  def logux_stream
    @logux_stream ||= Logux::Stream.new(response.stream)
  end
end
