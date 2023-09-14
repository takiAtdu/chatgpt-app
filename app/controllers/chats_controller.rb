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
end