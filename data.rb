require 'net/http'
require 'uri'
require 'rexml/document'
require 'date'

module DATA

  # словарь состояний параметра cloudiness, описанный на сайте
  CLOUDINESS  = {-1 => 'Туман', 0 => 'Ясно', 1 => 'Малооблачно', 2 => 'Облачно', 3 => 'Пасмурно'}
  # словарь состояний параметра precipitation, описанный на сайте
  PRECIPITATION = {
          3 => 'смешанные', 4 => 'дождь', 5 => 'ливень', 6 => 'снег',
          7 => 'снег', 8 => 'гроза', 9 => 'нет данных', 10 => 'без осадков'}
  # словарь состояний параметра tod (time of day), описанный на сайте
  TOD = {0 => 'ночь', 1 => 'утро', 2 => 'день', 3 => 'вечер'}
  # словарь направлений ветра
  WIND_DIRECTION = {
          0 => 'северный', 1 => 'северо-восточный', 
          2 => 'восточный',3 => 'юго-восточный', 
          4 => 'южный', 5 => 'юго-западный', 
          6 => 'западный', 7 => 'северо-западный' }


  # Возвращает массив хэшей прогноза погоды на четыре времени суток 
  # в зависимости от момента запроса c интервалом в 6 часов (3, 9, 15, 21)
  def self.get_forecast_array(current_tod, city_code)
    uri = URI.parse("https://xml.meteoservice.ru/export/gismeteo/point/" + city_code + ".xml")
    doc = ''
    begin
      response = Net::HTTP.get_response(uri)
      doc = REXML::Document.new(response.body) # XML parser
    rescue
      puts 'There is an error while sending request to xml.meteoservice.ru'
      return []
    end

    city_name_encoded = doc.root.elements['REPORT/TOWN'].attributes['sname'] # short city name http-encoded
    city_name = URI.unescape(city_name_encoded) # decode city name from http-encoded

    forecast_array = []

    # get all xml-elements from root element
    doc.root.elements['REPORT/TOWN'].elements.each do |current_element|
      # exclude two unnecessary indicators
      # PRESSURE -	атмосферное давление, в мм.рт.ст.
      # RELWET -	относительная влажность воздуха, в % 

      next if current_element.attributes['tod'].to_i != current_tod

      forecast = {}
      forecast[:city_name] = city_name
      forecast[:day] = current_element.attributes['day']
      forecast[:month] = current_element.attributes['month']
      forecast[:year] = current_element.attributes['year']
      forecast[:hour] = current_element.attributes['hour'].to_i
      forecast[:tod_index] = current_element.attributes['tod'].to_i # index of time a day
      forecast[:tod] = TOD[forecast[:tod_index]] # name of time a dat according to vocabulary index
      forecast[:min_temp] = current_element.elements['TEMPERATURE'].attributes['min']
      forecast[:max_temp] = current_element.elements['TEMPERATURE'].attributes['max']
      forecast[:min_wind] = current_element.elements['WIND'].attributes['min'] # (m/s)
      forecast[:max_wind] = current_element.elements['WIND'].attributes['max'] # (m/s)
      forecast[:wind_direction_index] = current_element.elements['WIND'].attributes['direction'].to_i
      forecast[:wind_direction] = WIND_DIRECTION[forecast[:wind_direction_index]]
      forecast[:clouds_index] = current_element.elements['PHENOMENA'].attributes['cloudiness'].to_i # cloudiness index
      forecast[:clouds] = CLOUDINESS[forecast[:clouds_index]]
      forecast[:precipitation_index] = current_element.elements['PHENOMENA'].attributes['precipitation'].to_i # precipitation index
      forecast[:precipitation] = PRECIPITATION[forecast[:precipitation_index]]
      # комфорт - температура воздуха по ощущению одетого по сезону человека, выходящего на улицу
      forecast[:heat_min] = current_element.elements['HEAT'].attributes['min']
      forecast[:heat_max] = current_element.elements['HEAT'].attributes['max']

      forecast_array << forecast
    end
    return forecast_array
  end


end
