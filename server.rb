require 'rack'
require 'json'
require 'pry'

class Server
  ENV_VAR_LIST = %w(SECRET_PHRASE POD_NAME POD_IP HOST_IP)

  def initialize
    @secrets = SecretLoader.new
  end

  def call(env)
    if env['REQUEST_PATH'].end_with?('.json')
      [200, { "Content-Type" => "application/javascript" }, [output_vars.to_json]]
    else
      [200, { "Content-Type" => "text/html" }, [html_output]]
    end
  end

  private

  def html_output
    <<-EO_HTML
<html>
<head><title>Tech Talk demo!</title></head>
<body>
  <h1>Check out this fancy HTML!</h1>
  <h2>Variables</h2>
  <ul>
#{ output_vars.map { |k,v| "<li><b>#{k}</b> = #{v}</li>\n" }.join("\n") }
  </ul>
</html>
    EO_HTML
  end

  def output_vars
    vars = {
      'TIME' => Time.now
    }
    ENV_VAR_LIST.each do |var|
      vars[var] = @secrets[var] if @secrets[var]
    end

    vars
  end
end

# Copied from samson_secret_puller gem
# https://github.com/zendesk/samson_secret_puller/blob/master/gem/lib/samson_secret_puller.rb
class SecretLoader
  FOLDER = '/secrets'.freeze
  TIMEOUT = 60

  def [](key)
    secrets[key]
  end

  def fetch(*args, &block)
    secrets.fetch(*args, &block)
  end

  def keys
    secrets.keys
  end

  private

  def secrets
    @secrets ||= begin
      secrets = ENV.to_h

      if File.exist?(FOLDER)
        wait_for_secrets_to_appear
        merge_secrets(secrets)
      end

      secrets
    end
  end

  def merge_secrets(secrets)
    Dir.glob("#{FOLDER}/*").each do |file|
      name = File.basename(file)
      next if name.start_with?(".") # ignore .done and maybe others
      secrets[name] = File.read(file).strip
    end
  end

  def wait_for_secrets_to_appear
    start = Time.now
    done_file = "#{FOLDER}/.done"

    # secrets should appear in that folder any second now
    until File.exist?(done_file)
      time_waited = Time.now - start
      if time_waited > TIMEOUT
        raise TimeoutError, "Waited #{TIMEOUT} seconds for #{done_file} to appear. I quit."
      else
        puts "waiting for secrets to appear (waited #{time_waited} seconds so far)..."
        sleep 1
      end
    end
  end
end
