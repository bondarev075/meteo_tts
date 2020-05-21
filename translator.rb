# Transform forecast in text
module Translator

  TOD = {0 => "Ночью", 1 => "Утром", 2 => "Днем", 3 => "Вечером"} 

  def self.translate_to_text(forecast_array)
    text_array = []
    forecast_array.each do |frcst|
      text_string = ''
      tmp_arr = []
      tmp_arr << TOD[frcst[:tod_index]] + " " + frcst[:clouds] + ", " + frcst[:precipitation]
      tmp_arr << "Температура от " + frcst[:min_temp] + " до " + frcst[:max_temp] + " градусов"
      tmp_arr << "Ощущается как " + frcst[:heat_min] + " градусов"
      tmp_arr << "Ветер " + frcst[:wind_direction] + " от " + frcst[:min_wind] + " до " + frcst[:max_wind] + " метров в секунду"
      tmp_arr << "Внимание! Сильный ветер!" if frcst[:min_wind].to_i > 6 || frcst[:max_wind].to_i > 6
      
      text_string = tmp_arr.join '. '
      text_string.strip!
      text_array << text_string
    end
    return text_array
  end

end
