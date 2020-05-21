require 'net/http'
# require 'byebug'
require 'json'
require 'uri'
require "base64"


module TTS

  # 0. check if session exists
  def self.session_is_active?

    server = "https://cp.speechpro.com"
    resource = "/vksession/rest/session"
    cookie = self.read_cookie
    uri = URI(server + resource)
    req = Net::HTTP::Get.new(uri, 'Content-Type' => 'application/json')
    req['X-Session-Id'] = cookie 
    http = Net::HTTP.new(uri.hostname, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    
    response = http.request(req)

    case response
    when Net::HTTPSuccess then
      response_hash = JSON.parse(response.body)
      return response_hash['is_active']
    when Net::HTTPRedirection then
      location = response['location']
      warn "redirected to #{location}"
      get_page(location, limit - 1)
    else
      puts 'session is not active'
      return false
    end
  end


  # 1. make new session
  def self.set_session (domain_id, login, password)
    server = "https://cp.speechpro.com"
    resource = "/vksession/rest/session"
    uri = URI(server + resource)
    req = Net::HTTP::Post.new(uri, 'Content-Type' => 'application/json')
    req.body = {domain_id: domain_id, password: password, username: login}.to_json
    http = Net::HTTP.new(uri.hostname, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    
    response = http.request(req)

    case response
    when Net::HTTPSuccess then
      hash = JSON.parse(response.body)
      cookie = hash['session_id']
      save_cookie(cookie)
      puts 'new session is activated'
    when Net::HTTPRedirection then
      location = response['location']
      warn "redirected to #{location}"
      get_page(location, limit - 1)
    else
      puts 'Error: ' + response.code
      return false
    end
  end


  # 4. get wave file
  def self.get_file (speech_text, file_name="forecast.wav", voice_name="Anna_n")
    server = "https://cp.speechpro.com"
    resource = "/vktts/rest/v1/synthesize"
    cookie = self.read_cookie
    url = server + resource

    uri = URI(url)
    req = Net::HTTP::Post.new(uri, 'Content-Type' => 'application/json')
    req['X-Session-Id'] = cookie 
    req.body = {voice_name: voice_name, text: {mime: "text/plain", value: speech_text}, audio: "audio/wav"}.to_json
    http = Net::HTTP.new(uri.hostname, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    response = http.request(req)

    case response
    when Net::HTTPSuccess then
      hash = JSON.parse(response.body)
      audio_data = hash['data']
      decode_base64_content = Base64.decode64(audio_data) 
      File.open(file_name, "wb") do |f|
        f.write(decode_base64_content)
      end
      puts 'save file ' + file_name
      return true
    when Net::HTTPRedirection then
      location = response['location']
      warn "redirected to #{location}"
      get_page(location, limit - 1)
    else
      puts 'Error: ' + response.code
      return response.value
    end
  end


  # # 2. get available languages (можно не получать список языков, если язык известен)
  def self.get_available_languages
    # url = "https://cp.speechpro.com/vktts/rest/v1/languages"
    # cookie = read_cookie
    # res = get_data(url, '', '', cookie)
    # # puts res.inspect
    # arr = JSON.parse(res)
    # puts arr.inspect
    # hash = arr[2] # Russian
    # puts hash['name']
  end


  # # 3. get available voices (можно не получать список голосов, если имя голоса известно)
  def self.get_available_voices
    # server = "https://cp.speechpro.com"
    # uri = "/vktts/rest/v1/languages/Russian/voices"
    # cookie = read_cookie
    # url = server + uri
    # res = get_data(url, '', '', cookie)
    # # СЮДА ВЕРНЕТСЯ ТЕЛО ОТВЕТА, НУЖНО РАСПАРСИТЬ ДЖЕЙСОН
    # # puts res.inspect
    # arr = JSON.parse(res)
    # arr.each do |voice|
    #   puts voice['id'].to_s + ". " + voice['name'] + " (" + voice['gender'] + ")"
    # end
    # # hash = arr[5] # Anna_n
    # # hash = arr[10] # Julia_n
    # # hash = arr[13] # Lydia
    # # hash = arr[15] # Maria
    # # hash = arr[17] # Victoria
    # # puts hash['name']
  end


  # get response from server
  def self.get_data (url, login, password, cookie='')
    uri = URI(url)
    req = ''
    if cookie
      req = Net::HTTP::Get.new(uri, 'Content-Type' => 'application/json')
      req['X-Session-Id'] = cookie 
    else
      req = Net::HTTP::Post.new(uri, 'Content-Type' => 'application/json')
      req.body = {domain_id: 1059, password: password, username: login}.to_json
    end
    http = Net::HTTP.new(uri.hostname, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    response = http.request(req)
    case response
    when Net::HTTPSuccess then
      response.body
    when Net::HTTPRedirection then
      location = response['location']
      warn "redirected to #{location}"
      get_page(location, limit - 1) # рекурсия
    else
      puts
      puts 'Ошибка загрузки: ' + url + " " + response.code + " " + response.value
      return response.value
    end
  end


  # read cookie from file
  def self.read_cookie
    file_name = File.expand_path(File.dirname(__FILE__)) + '/cookie.txt'
    if !File.file? file_name
      return ''
    end
    cookie = File.open(file_name){ |file| file.read }
    cookie.strip!
    return cookie
  end


  # save cookie to file
  def self.save_cookie (cookie)
    file_name = File.expand_path(File.dirname(__FILE__)) + '/cookie.txt'
    if !File.file? file_name
      # puts 'cant find file cookie.txt'
      return false
    end
    File.open(file_name, 'w') do |file|
      puts 'cookie to save ' + cookie
      file.puts cookie
    end
    return true
  end
end
