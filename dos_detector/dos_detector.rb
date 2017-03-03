Server = get_server_class
r = Server::Request.new
cache = Userdata.new.shared_cache
global_mutex = Userdata.new.shared_mutex

config = {
  :counter_key => r.hostname,
  :magic_str => "....",

  :behind_counter => -500,

  :threshold_counter => 100,
  :threshold_time => 1,

  :expire_time => 5,
}

unless r.sub_request?
  # process-shared lock
  timeout = global_mutex.try_lock_loop(50000) do
    dos = DosDetector.new r, cache, config
    data = dos.analyze
    Server.errlogger Server::LOG_NOTICE, "[INFO] dos_detetor: detect dos: #{data}"
    begin
      if dos.detect?
        Server.errlogger Server::LOG_NOTICE, "dos_detetor: detect dos: #{data}"
        Server.return Server::HTTP_SERVICE_UNAVAILABLE
      end
    rescue => e
      raise "DosDetector failed: #{e}"
    ensure
      global_mutex.unlock
    end
  end
  if timeout
    Server.errlogger Server::LOG_NOTICE, "dos_detetor: get timeout mutex lock, #{data}"
  end
end

