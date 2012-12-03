if defined? Unicorn
  # Unicorn self-process killer
  require 'unicorn/worker_killer'
  
  # Max memory size (RSS) per worker
  use Unicorn::WorkerKiller::Oom, (256 + Random.rand(32)) * 1024**2
end

# Run
require ::File.expand_path('../config/environment',  __FILE__)
run Cloudchart::Application
