class ChatsController < ApplicationController
  def form
    @chat = Chat.new
  end

  def form_submitted
    @chat = Chat.new(chat_params)
    accepted_format = [".mp3"]
    filename = @chat.mp3_file.filename
    if accepted_format.any? { |t| filename.include?(t) }
      if @chat.save
        transcribed_text = transcribe(@chat)
        summarized_text = summarize(transcribed_text)
        @chat.update(transcribed_text: transcribed_text, summarized_text: summarized_text)
        redirect_to action: :show, id: @chat.id
      else
        puts "保存失敗"
        redirect_to action: :form
      end
    else
      puts "拡張子不適"
      redirect_to action: :form
    end
  end

  def show
    @chat = Chat.find(params[:id])
  end


  private
    def chat_params
      params.require(:chat).permit(:id, :mp3_file, :transcribed_text, :summarized_text)
    end

    def create_tempfile(chat)
      s3_client = Aws::S3::Client.new(region: "ap-northeast-1", access_key_id: ENV["ACCESS_KEY_ID"], secret_access_key: ENV["SECRET_ACCESS_KEY"])
      file = s3_client.get_object(bucket: "chatgpt-app-storage", key: chat.mp3_file.key).body.read
      
      tempfile = Tempfile.open(["temp", ".mp3"])
      tempfile.binmode
      tempfile.write(file)
      tempfile.rewind

      return tempfile
    end

    def transcribe(chat)
      tempfile = create_tempfile(chat)

      client = OpenAI::Client.new(access_token: ENV["OPENAI_API_KEY"])
      response = client.transcribe(
      parameters: {
          model: "whisper-1",
          file: File.open(tempfile, 'rb'),
      })

      return response
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
end