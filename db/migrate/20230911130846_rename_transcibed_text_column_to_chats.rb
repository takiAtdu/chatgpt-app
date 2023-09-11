class RenameTranscibedTextColumnToChats < ActiveRecord::Migration[7.0]
  def change
    rename_column :chats, :transcibed_text, :transcribed_text
  end
end
