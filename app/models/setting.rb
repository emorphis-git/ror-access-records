class Setting < ActiveRecord::Base
  DATE_FORMATS = [
    '%Y-%m-%d',
    '%d/%m/%Y',
    '%d.%m.%Y',
    '%d-%m-%Y',
    '%m/%d/%Y',
    '%d %b %Y',
    '%d %B %Y',
    '%b %d, %Y',
    '%B %d, %Y'
  ]

  TIME_FORMATS = [
    '%H:%M',
    '%I:%M %p'
  ]
  
  def self.read_formatted_setting(value, format)
    case format
    when "boolean"
      ActiveRecord::Type::Boolean.new.cast(value)
    when "symbol"
      value.to_sym
    when "int"
      value.to_i
    when "date"
      Date.parse value
    when "datetime"
      DateTime.parse value
    else
      value
    end
  end
end
