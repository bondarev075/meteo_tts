require 'date'
require 'dotenv'
require 'telegram/bot'
require_relative 'data'
require_relative 'translator'
require_relative 'tts'

Dotenv.load('config.env')
Dotenv.require_keys("BOT_TOKEN", "CHAT_ID", "TTS_LOGIN", "TTS_PASSWORD", "TTS_DOMAIN_ID")

CITY_CODE = '99' #Novosibirsk
AUDIOFILE_NAME = 'forecast.wav'

# forecast points: 3, 9, 15, 21
current_tod = 0
case Time.now.hour
when 0..3
  current_tod = 0
when 4..11
  current_tod = 1
when 12..16
  current_tod = 2
when 17..21
  current_tod = 3
when 22..23
  current_tod = 0
end


start_time = Time.now
forecast_array = DATA.get_forecast_array current_tod, CITY_CODE
exit if forecast_array.empty?
forecast_text_array = Translator.translate_to_text(forecast_array)
puts 'Прогноз:'
puts forecast_text_array
puts 'Time to get forecast text: ' + (Time.now - start_time).to_s + ' sec.'

puts 'Wait for audio will be generated (it may take about 20 seconds and more)'
start_time = Time.now
# Let's vocalize forecast for one time of the day
speech_text = forecast_text_array[0]
TTS.set_session ENV['TTS_DOMAIN_ID'], ENV['TTS_LOGIN'], ENV['TTS_PASSWORD'] if !TTS.session_is_active?
res = TTS.get_file speech_text, AUDIOFILE_NAME
puts 'Time to generate audio file: ' + (Time.now - start_time).to_s + ' sec.'

start_time = Time.now
Telegram::Bot::Client.run(ENV['BOT_TOKEN']) do |bot|
  bot.api.send_voice(chat_id: ENV['CHAT_ID'], title: 'Weather forecast for the day', voice: Faraday::UploadIO.new(AUDIOFILE_NAME, 'audio/ogg'))
end
puts 'Time to send audio to the bot: ' + (Time.now - start_time).to_s + ' sec.'
