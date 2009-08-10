# Default DATE_FORMATS available
#
# Time::DATE_FORMATS.merge!({
#     :db => "%Y-%m-%d %H:%M:%S",
#     :number => "%Y%m%d%H%M%S",
#     :time => "%H:%M",
#     :mdy => "%B %d, %Y",
#     :short => "%d %b %H:%M",
#     :long => "%B %d, %Y %H:%M"
# })
# === Example Useage
# DateTime.now().to_format(:mdy)
#
class DateTime
  # Helper method for string formatting DateTime.
  def to_format(key = :default)
    if format = ::Time::DATE_FORMATS[key]
      strftime(format)
    else
      to_s
    end
  end
end
