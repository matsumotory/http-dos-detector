# http-dos-detector

Detect the huge number of access like DoS for Apache httpd (nginx) using mod_mruby (ngx_mruby)

## Install and Configuration
- install mod_mruby if you use apache
- install ngx_mruby if you use nginx

### Apache and mod_mruby
- copy `dos_detector/` and `dos_detector_apache.conf` into `/etc/httpd/conf.d/`
```apache
LoadModule mruby_module modules/mod_mruby.so

<IfModule mod_mruby.c>
  mrubyPostConfigMiddle         /etc/httpd/conf.d/dos_detector/dos_detector_init.rb cache
  mrubyChildInitMiddle          /etc/httpd/conf.d/dos_detector/dos_detector_worker_init.rb cache
  mrubyAccessCheckerMiddle      /etc/httpd/conf.d/dos_detector/dos_detector.rb cache
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
      mruby_access_checker /path/to/nginx/conf/doc_detector/dos_detector.rb cache;
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

dos = DosDetector.new r, cache, config

mutex.lock
begin
  Server.return Server::HTTP_SERVICE_UNAVAILABLE if dos.detect?
rescue => e
  raise "DosDetector failed: #{e}"
ensure
  mutex.unlock
end
```

## depend mrbgem
```ruby
  conf.gem :github => 'matsumoto-r/mruby-cache'
  conf.gem :github => 'matsumoto-r/mruby-mutex'
```

## License
under the MIT License:
- see LICENSE file

