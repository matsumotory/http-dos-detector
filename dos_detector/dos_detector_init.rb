Userdata.new.shared_mutex = Mutex.new :global => true

class DosDetector
  def initialize r, c, config
    @r = r
    @cache = c
    @config = config
    @now = Time.now.to_i
    @counter_key = config[:counter_key].to_s
    @counter_key_time = "#{@counter_key}_#{config[:magic_str]}_time"
    @data = self._analyze

    self._detect @data
  end

  def analyze
    @data
  end

  def _analyze
    unless @counter_key.nil?
      cnt = @cache[@counter_key]
      cnt = cnt.to_i

      # counter time when initialized counter
      prev = @cache[@counter_key_time].to_i
      diff = @now - prev

      # time initialized
      diff = 0 if prev == 0
      {:file => @r.filename, :time_diff => diff, :counter => cnt, :counter_key => @counter_key}
    else
      nil
    end
  end

  def init_cache data
    @cache[@counter_key] = 1.to_s if data[:counter] == 0
    @cache[@counter_key_time] = @now.to_s if data[:time_diff] == 0
  end

  def update_cache counter, date
    @cache[@counter_key] = (counter + 1).to_s
    @cache[@counter_key_time] =  date.to_s
  end

  def detect? data=nil
 
    # run anlyze when data is nothing
    data = self.analyze if data.nil?
    return false if data.nil?

    thr = @config[:threshold_counter]
    thr_time = @config[:threshold_time]
    expire = @config[:expire_time]
    behind = @config[:behind_counter]
    cnt = data[:counter]
    diff = data[:time_diff]

    if cnt >= thr
      if 0 <= diff && diff < thr_time
        true
      else
        false
      end
    elsif cnt < 0
      if diff > expire
        false
      else
        true
      end
    else
      false
    end
  end

  def _detect data=nil

    # run anlyze when data is nothing
    data = self.analyze if data.nil?
    return false if data.nil?

    self.init_cache data

    thr = @config[:threshold_counter]
    thr_time = @config[:threshold_time]
    expire = @config[:expire_time]
    behind = @config[:behind_counter]
    cnt = data[:counter]
    diff = data[:time_diff]

    if cnt >= thr
      if 0 <= diff && diff < thr_time
        self.update_cache behind, @now
      else
        self.update_cache 0, @now
      end
    elsif cnt < 0 && diff > expire
      self.update_cache 0, @now
    else
      self.update_cache cnt, (@now - diff)
    end
  end

end
