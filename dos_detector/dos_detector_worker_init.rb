config = {:namespace =>"dos_detector"}

c = Cache.new config
c.clear

Userdata.new.shared_cache = c

