class ChatsController < ApplicationController
  def form
    @chat = Chat.new
  end

  def form_submitted
    @chat = Chat.new(chat_params)
    accepted_format = [".mp3"]
    if accepted_format.include?(@chat.mp3_file)
      if @chat.save
        redirect_to action: :form
      end
    else
      redirect_to action: :form
    end
  end

  def show
    @chat = Chat.find(params[:id])
  end



  def index
    client = OpenAI::Client.new(access_token: ENV["OPENAI_API_KEY"])
    response = client.chat(
      parameters: {
        model: "gpt-3.5-turbo",
        messages: [
          { role: "user", content: "hello" }
        ],
      },
    )

    @message = response.dig("choices", 0, "message", "content")
  end

  def input
  end

  def output
    input = params[:input]

    client = OpenAI::Client.new(access_token: ENV["OPENAI_API_KEY"])
    response = client.chat(
      parameters: {
        model: "gpt-3.5-turbo",
        messages: [
          { role: "user", content: input }
        ],
      },
    )

    @output = response.dig("choices", 0, "message", "content")
  end

  def chat
    if params[:input]
      @input = params[:input]

      client = OpenAI::Client.new(access_token: ENV["OPENAI_API_KEY"])
      response = client.chat(
        parameters: {
          model: "gpt-3.5-turbo",
          messages: [
            { role: "user", content: @input }
          ],
        },
      )

      @output = response.dig("choices", 0, "message", "content")
    end
  end

  private
    def chat_params
      params.require(:chat).permit(:mp3_file)
    end
end