class ApplicationController < ActionController::Base

  def create_tempfile(file)      
    tempfile = Tempfile.open(["temp", ".mp3"])
    tempfile.binmode
    tempfile.write(file)
    tempfile.rewind

    return tempfile
  end

  def transcribe(tempfile)
    client = OpenAI::Client.new(access_token: ENV["OPENAI_API_KEY"])
    response = client.transcribe(
    parameters: {
        model: "whisper-1",
        file: File.open(tempfile, 'rb'),
    })

    return response.dig("text")
  end

  def summarize(transcribed_text)
    prompt = """
      次のテキストを要約してください。

      【テキスト】
    """+transcribed_text

    client = OpenAI::Client.new(access_token: ENV["OPENAI_API_KEY"])
    response = client.chat(
      parameters: {
        model: "gpt-3.5-turbo",
        messages: [
          { role: "user", content: prompt }
        ],
      },
    )

    return response.dig("choices", 0, "message", "content")
  end

  def split_mp3(tempfile)
    # FFMPEGのインスタンスで処理
    basefile = FFMPEG::Movie.new(tempfile.path)
    duration = basefile.duration
    split_count = (duration/480).floor + 1

    tempfile_list = []
    dir_path = File.dirname(tempfile.path)
    basename = File.basename(tempfile.path, ".mp3")
    basepath = File.join(dir_path, basename)

    split_count.times do |n|
      tempfile_new = basepath + "_" + n.to_s + ".mp3"
      `ffmpeg -ss #{5*60*n} -i "#{tempfile.path}" -t #{5*60*(n+1)} "#{tempfile_new}"`

      # tempfile_new = Tempfile.open(["temp", ".mp3"])
      # tempfile_new.binmode
      # `ffmpeg -ss #{300*n} -i "#{tempfile.path}" -t #{300*(n+1)} "#{tempfile_new.path}"`
      # tempfile_new.rewind

      tempfile_list.push(tempfile_new)
    end

    return tempfile_list
  end

end
