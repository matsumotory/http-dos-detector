Server = get_server_class
r = Server::Request.new
cache = Userdata.new.shared_cache
global_mutex = Userdata.new.shared_mutex
host = r.hostname

config = {
  # dos counter by key
  :counter_key => host,

  # judging dos access when the number of counter is between :behind_counter and 0
  :behind_counter => -500,

  # set behind counter when the number of counter is over :threshold_counter
  # in :threshold_time sec
  :threshold_counter => 100,
  :threshold_time => 1,

  # expire dos counter and initialize counter even
  # if the number of counter is between :behind_counter and 0
  :expire_time => 5,
}

# process-shared lock
global_mutex.try_lock_loop do
  dos = DosDetector.new r, cache, config
  begin
    Server.return Server::HTTP_SERVICE_UNAVAILABLE if dos.detect?
  rescue => e
    raise "DosDetector failed: #{e}"
  ensure
    global_mutex.unlock
  end
end

