class ChatsController < ApplicationController
  def form
    @chat = Chat.new
  end

  def form_submitted
    @chat = Chat.new(chat_params)
    accepted_format = [".mp3"]
    filename = @chat.mp3_file.filename
    # if accepted_format.any? { |t| filename.include?(t) }
      if @chat.save
        s3_client = Aws::S3::Client.new(region: "ap-northeast-1", access_key_id: ENV["ACCESS_KEY_ID"], secret_access_key: ENV["SECRET_ACCESS_KEY"])
        file = s3_client.get_object(bucket: "chatgpt-app-storage", key: @chat.mp3_file.key).body.read
        tempfile = create_tempfile(file)
        tempfile_list = split_mp3(tempfile)

        transcribed_text = ""
        summarized_text = ""
        tempfile_list.each do |file|
          transcribed_text_part = transcribe(file)
          transcribed_text += transcribed_text_part
          summarized_text_part = summarize(transcribed_text)
          summarized_text += summarized_text_part
        end
        @chat.update(transcribed_text: transcribed_text, summarized_text: summarized_text)
        redirect_to action: :show, id: @chat.id
      else
        puts "保存失敗"
        redirect_to action: :form
      end
    # else
    #   puts "拡張子不適"
    #   redirect_to action: :form
    # end
  end

  def show
    @chat = Chat.find(params[:id])
  end


  private
    def chat_params
      params.require(:chat).permit(:id, :mp3_file, :transcribed_text, :summarized_text)
    end

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