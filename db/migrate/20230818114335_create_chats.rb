class CreateChats < ActiveRecord::Migration[7.0]
  def change
    create_table :chats do |t|
      t.string :path_to_audio_file
      t.string :transcibed_text
      t.string :summarized_text

      t.timestamps
    end
  end
end
