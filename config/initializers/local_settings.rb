class Time
#  alias old_strftime strftime

#  def strftime(*args)
#    in_time_zone("Europe/Stockholm").old_strftime(*args)
#  end

  def full_time
    strftime("%Y-%m-%d %H:%M:%S")
  end

  def short_time
    strftime("%Y-%m-%d %H:%M:%S")
  end
end
