require 'active_support/core_ext/hash/keys'
require 'erb'
require 'yaml'
require 'fileutils'

namespace :monit do
  desc 'Start Monit daemon'
  task :start => :config do
    Rake::Task['monit:config'].execute
    ss = parse_monit_settings
    run "#{ss[:bin_path]} -c #{ss[:config_path]} -p #{ss[:pid_path]} -d #{ss[:interval]} -l #{ss[:log_path]}"
  end

  desc 'Stop Monit daemon (without stopping workers)'
  task :stop do
    ss = parse_monit_settings
    run "#{ss[:bin_path]} -c #{ss[:config_path]} -p #{ss[:pid_path]} -d #{ss[:interval]} quit"
  end

  desc 'Restart Monit daemon'
  task :restart do
    Rake::Task['monit:stop'].execute
    sleep(3)
    Rake::Task['monit:start'].execute
  end

  desc 'Generate *only* Monit configuration file'
  task :config do
    monit_settings = parse_monit_settings
    workers = parse_workers_settings

    erb = ERB.new(CONFIG_TEMPLATE.split("\n").map(&:strip).join("\n"))
    monit_config = erb.result(binding)

    open(monit_settings[:config_path], 'w') do |fd|
      fd.write(monit_config)
    end
    File.chmod(0700, monit_settings[:config_path])
  end


  MONIT_YML_PATH = File.join("config", "monit.yml")
  WORKERS_YML_PATH = File.join("config", "workers.yml")

  CONFIG_TEMPLATE = <<-ERB
    set httpd port <%= monit_settings[:port] %> and
    allow <%= monit_settings[:user] %>:<%= monit_settings[:pass] %>

    <% workers.each do |worker| %>
      check process <%= worker[:id] %> with pidfile "<%= worker[:pidfile] %>"
      group workers
      start program "/bin/bash -l -c 'cd <%= PADRINO_ROOT %>; PADRINO_ENV=production VERBOSE=1 HOME=<%= File.expand_path('.', '~') %> QUEUE=<%= worker[:queues].join(',') %> BACKGROUND=yes PIDFILE=<%= worker[:pidfile] %> bundle exec rake resque:work  >> <%= worker[:log] %>  2>> <%= worker[:err_log] %>'"
      stop program  "/bin/kill `cat <%= worker[:pidfile] %>`"
      alert <%= monit_settings[:alert_email] %> but not on { nonexist timeout }
    <% end %>
  ERB

  def parse_monit_settings
    ss = load_settings(MONIT_YML_PATH)

    # Make pid and log directories if they don't exist
    # (monit might fail to start).
    [:pid_path, :log_path].each do |path_key|
      FileUtils.mkdir_p(ss[path_key].split("/")[0..-2].join("/"))
    end

    # Get absolute paths
    [:bin_path, :config_path, :pid_path, :log_path].each do |path_key|
      ss[path_key] = File.expand_path(ss[path_key])
    end

    return ss
  end

  def parse_workers_settings
    settings = load_settings(WORKERS_YML_PATH)

    res = []
    settings.each_pair do |name, options|
      (1..options['num']).each do |i|
        id = "resque_worker-#{name}-#{i}"

        log_filename = "workers__#{options['queues'].uniq.sort.join('-')}"
        log = File.join(PADRINO_ROOT, 'log', "#{log_filename}.log")
        err_log = File.join(PADRINO_ROOT, 'log', "#{log_filename}.err.log")
        queues = options['queues']

        res << {
          :id => id,
          :pidfile => File.join(PADRINO_ROOT, 'tmp', 'pids', "#{id}.pid"),
          :queues => queues,
          :log => log,
          :err_log => err_log,
        }
      end
    end

    res
  end

  def run(command)
    logger.debug(command)
    out = `#{command}`
    logger.debug(out.gsub("\n", '\n'))
    return out
  end

  def load_settings(path)
    abs_path = File.join(PADRINO_ROOT, path)
    if not File.exists?(abs_path)
      raise "#{path} does not exist! Use #{path}.sample as a template"
    end
    res = YAML.load_file(abs_path)
    res.symbolize_keys
  end
end