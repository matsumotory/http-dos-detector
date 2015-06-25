Server = get_server_class
r = Server::Request.new
cache = Userdata.new.shared_cache
global_mutex = Userdata.new.shared_mutex

host = r.hostname

short_dos_conf = {
  :counter_key => "#{host}...1",
  :behind_counter => -1000,
  :threshold_counter => 1000,
  :threshold_time => 2,
  :expire_time => 2,
}

long_dos_conf = {
  :counter_key => "#{host}...2",
  :behind_counter => -5000,
  :threshold_counter => 5000,
  :threshold_time => 5,
  :expire_time => 5,
}

if ! r.sub_request? && ! host.nil?

  short_dos = DosDetector.new r, cache, short_dos_conf
  long_dos = DosDetector.new r, cache, long_dos_conf

  Server.errlogger Server::LOG_NOTICE, "long dos analyze: #{long_dos.analyze}"
  Server.errlogger Server::LOG_NOTICE, "short dos analyze: #{short_dos.analyze}"

  timeout = global_mutex.try_lock_loop(50000) do
    begin
      if short_dos.detect? && long_dos.detect?
      	Server.return Server::HTTP_SERVICE_UNAVAILABLE
      end
    rescue => e
      raise "DosDetector failed: #{e}"
    ensure
      global_mutex.unlock
    end
  end

  if timeout
    Server.errlogger Server::LOG_NOTICE, "dos_detector.rb: get timeout lock, #{host}"
  end

end

