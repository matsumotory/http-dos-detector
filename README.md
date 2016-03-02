# http-dos-detector

Detect Huge Number of HTTP Requests on Apache and Nginx using mruby code.

http-dos-detector use same Ruby code between Apache(mod_mruby) and nginx(ngx_mruby).

## Install and Configuration
- install [mod_mruby](https://github.com/matsumoto-r/mod_mruby) if you use apache
- install [ngx_mruby](https://github.com/matsumoto-r/ngx_mruby) if you use nginx

### Apache and mod_mruby
- copy `dos_detector/` and `dos_detector_apache.conf` into `/etc/httpd/conf.d/`
```apache
LoadModule mruby_module modules/mod_mruby.so

<IfModule mod_mruby.c>
  mrubyPostConfigMiddle    /etc/httpd/conf.d/dos_detector/dos_detector_init.rb cache
  mrubyChildInitMiddle     /etc/httpd/conf.d/dos_detector/dos_detector_worker_init.rb cache
  mrubyAccessCheckerMiddle /etc/httpd/conf.d/dos_detector/dos_detector.rb cache
</IfModule>
```

### nginx and ngx_mruby
- copy `dos_detector/` into `/path/to/nginx/conf.d/`
- write configuration like `dos_detector_nginx.conf`
```nginx
http {
  mruby_init /path/to/nginx/conf/doc_detector/dos_detector_init.rb cache;
  mruby_init_worker /path/to/nginx/conf/doc_detector/dos_detector_worker_init.rb cache;
  server {
    location /dos_detector {
      mruby_access_handler /path/to/nginx/conf/doc_detector/dos_detector.rb cache;
    }
  }
}
```
### programmable configuration of DoS
- `dos_detector.rb`
```ruby
Server = get_server_class
r = Server::Request.new
cache = Userdata.new.shared_cache
global_mutex = Userdata.new.shared_mutex
host = r.hostname

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
```

## depend mrbgem
```ruby
  conf.gem :github => 'matsumoto-r/mruby-cache'
  conf.gem :github => 'matsumoto-r/mruby-mutex'
```

http-dos-detector has the counter of any key in process-shared memory. When Apache or nginx was restarted, the counter was freed.

## License
under the MIT License:
- see LICENSE file

