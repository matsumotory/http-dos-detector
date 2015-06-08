Server = get_server_class
r = Server::Request.new
cache = Userdata.new.shared_cache
mutex = Userdata.new.shared_mutex

config = {
  # dos counter by key
  :counter_key => r.hostname,

  # judging dos access when the number of counter is between :behind_counter and 0
  :behind_counter => -2000,

  # set behind counter when the number of counter is over :threshold_counter
  # in :threshold_time sec
  :threshold_counter => 10000,
  :threshold_time => 5,

  # expire dos counter and initialize counter even
  # if the number of counter is between :behind_counter and 0
  :expire_time => 10,
}

host = r.hostname
dos = DosDetector.new r, cache, config

mutex.lock
begin
  Server.return Server::HTTP_SERVICE_UNAVAILABLE if dos.detect?
rescue => e
  raise "DosDetector failed: #{e}"
ensure
  mutex.unlock
end

