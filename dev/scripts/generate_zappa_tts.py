import os
import markdown
from bs4 import BeautifulSoup
from google.cloud import texttospeech

def strip_markdown(md_text):
    html = markdown.markdown(md_text)
    return BeautifulSoup(html, "html.parser").get_text()

def synthesize_speech(text, language_code, voice_name, output_path):
    print(f"Synthesizing {output_path}...")
    client = texttospeech.TextToSpeechClient()
    
    chunks = []
    current_chunk = ""
    for paragraph in text.split('\n'):
        if len(current_chunk) + len(paragraph) < 3000:
            current_chunk += paragraph + "\n"
        else:
            chunks.append(current_chunk)
            current_chunk = paragraph + "\n"
    if current_chunk:
        chunks.append(current_chunk)
        
    audio_content = b""
    for chunk in chunks:
        if not chunk.strip():
            continue
        synthesis_input = texttospeech.SynthesisInput(text=chunk)
        voice = texttospeech.VoiceSelectionParams(
            language_code=language_code,
            name=voice_name
        )
        audio_config = texttospeech.AudioConfig(
            audio_encoding=texttospeech.AudioEncoding.MP3,
            speaking_rate=0.9
        )
        response = client.synthesize_speech(
            input=synthesis_input, voice=voice, audio_config=audio_config
        )
        audio_content += response.audio_content

    with open(output_path, "wb") as out:
        out.write(audio_content)
    print(f"Saved {output_path}")

def main():
    files = [
        {
            "input": r"D:\HPZ440\ffs0\kb\moos-diary\t248-zappa-legt-de-situatie-uit-aan-audy.md",
            "lang": "nl-NL",
            "voice": "nl-NL-Wavenet-B", 
            "output": r"D:\HPZ440\ffs0\tmp\tts-probe\zappa_audy_letter_nl_full.mp3"
        },
        {
            "input": r"D:\HPZ440\ffs0\kb\moos-diary\t248-zappa-explains-the-situation-to-lola.md",
            "lang": "en-US",
            "voice": "en-US-Journey-D", 
            "output": r"D:\HPZ440\ffs0\tmp\tts-probe\zappa_lola_letter_en_full.mp3"
        },
        {
            "input": r"D:\HPZ440\ffs0\kb\moos-diary\20260708-t249-the-narrators-cut.md",
            "lang": "en-US",
            "voice": "en-US-Journey-D",
            "output": r"D:\HPZ440\ffs0\tmp\tts-probe\zappa_narrator_cut_en.mp3"
        }
    ]
    
    os.makedirs(r"D:\HPZ440\ffs0\tmp\tts-probe", exist_ok=True)

    for item in files:
        if not os.path.exists(item["input"]):
            print(f"Skipping {item['input']}, not found.")
            continue
        with open(item["input"], "r", encoding="utf-8") as f:
            md_text = f.read()
        
        if md_text.startswith("---"):
            parts = md_text.split("---", 2)
            if len(parts) >= 3:
                md_text = parts[2]
                
        plain_text = strip_markdown(md_text)
        
        if "authored-by:" in plain_text:
            plain_text = plain_text.split("authored-by:")[0]

        synthesize_speech(plain_text, item["lang"], item["voice"], item["output"])
    print("All done.")

if __name__ == "__main__":
    main()
