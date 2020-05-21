Погодный бот на основе данных сайта www.meteoservice.ru.
Отправляет сообщение с прогнозом погоды на день в выбранном городе.

To choose city code:
https://www.meteoservice.ru/content/export

The weather forecast for the day for choosen city divided by four times of day:
https://xml.meteoservice.ru/export/gismeteo/point/99.xml

Для запуска необходимо добавить в корень файл config.env, в котором прописать переменные окружения: токен бота и ID чата мессенджера Telegram.org, а также логин, пароль и ID домена сервиса голосовой озвучки https://cp.speechpro.com/service/tts:
BOT_TOKEN='XXXXXX'
CHAT_ID='XXXXXX'
TTS_LOGIN="xxx@mailserver.ru"
TTS_PASSWORD="xxxxxxx"
TTS_DOMAIN_ID="xxxx"