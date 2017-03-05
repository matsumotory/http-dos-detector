Userdata.new.shared_mutex = Mutex.new global: true

class DosDetector
  def initialize(r, c, config)
    @r = r
    @cache = c
    @config = config
    @now = Time.now.to_i
    @counter_key = config[:counter_key].to_s
    @counter_key_time = "#{@counter_key}_#{config[:magic_str]}_time"
    @data = _analyze

    _detect @data
  end

  def analyze
    @data
  end

  def _analyze
    if @counter_key.nil?
      @counter_key
    else
      cnt = @cache[@counter_key]
      cnt = cnt.to_i

      # counter time when initialized counter
      prev = @cache[@counter_key_time].to_i
      diff = @now - prev

      # time initialized
      diff = 0 if prev.zero?
      { file: @r.filename, time_diff: diff, counter: cnt, counter_key: @counter_key }
    end
  end

  def init_cache(data)
    @cache[@counter_key] = 1.to_s if data[:counter].zero?
    @cache[@counter_key_time] = @now.to_s if data[:time_diff].zero?
  end

  def update_cache(counter, date)
    @cache[@counter_key] = (counter + 1).to_s
    @cache[@counter_key_time] = date.to_s
  end

  def detect?(data = nil)
    # run anlyze when data is nothing
    data ||= analyze
    return false if data.nil?

    if data[:counter] >= @config[:threshold_counter]
      0 <= data[:time_diff] && data[:time_diff] < @config[:threshold_time]
    elsif data[:counter] < 0
      data[:time_diff] < @config[:expire_time]
    else
      false
    end
  end

  def _detect(data = nil)
    # run anlyze when data is nothing
    data ||= analyze
    return false if data.nil?

    init_cache data

    if data[:counter] >= @config[:threshold_counter]
      if 0 <= data[:time_diff] && data[:time_diff] < @config[:threshold_time]
        update_cache @config[:behind_counter], @now
      else
        update_cache 0, @now
      end
    elsif data[:counter] < 0 && data[:time_diff] > @config[:expire_time]
      update_cache 0, @now
    else
      update_cache data[:counter], (@now - data[:time_diff])
    end
  end
end
