import telebot
import yt_dlp
import os

TOKEN = "7872169900:AAEwuT1L8Jbxjl7IolgALsDvtwt2Gug6HRk"
bot = telebot.TeleBot(TOKEN)

def search_and_download_audio(query):
    ydl_opts = {
        'format': 'bestaudio/best',
        'noplaylist': True,
        'outtmpl': '%(title)s.%(ext)s',
        'quiet': True,
        'postprocessors': [{
            'key': 'FFmpegExtractAudio',
            'preferredcodec': 'mp3',
            'preferredquality': '192',
        }],
    }

    with yt_dlp.YoutubeDL(ydl_opts) as ydl:
        try:
            info = ydl.extract_info(f"ytsearch:{query}", download=True)['entries'][0]
            return ydl.prepare_filename(info).replace(".webm", ".mp3").replace(".m4a", ".mp3")
        except Exception as e:
            print("Error:", e)
            return None

@bot.message_handler(commands=['start'])
def send_welcome(message):
    bot.reply_to(message, "👋 سڵاو! ناوی گۆرانی یان بەشێک لێ بنێرە، ئەزموون دەکەم گۆرانیەکە بدۆزمەوە.")

@bot.message_handler(func=lambda message: True)
def echo_all(message):
    bot.reply_to(message, "⏳ گەڕان بۆ گۆرانی...")
    filename = search_and_download_audio(message.text)
    if filename and os.path.exists(filename):
        with open(filename, 'rb') as audio:
            bot.send_audio(message.chat.id, audio)
        os.remove(filename)
    else:
        bot.send_message(message.chat.id, "❌ ناتوانم گۆرانیەکە بدۆزمەوە.")

bot.infinity_polling()