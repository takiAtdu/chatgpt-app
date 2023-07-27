class ChatsController < ApplicationController
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
end
