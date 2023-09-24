class Chat < ApplicationRecord
    has_one_attached :mp3_file
    has_one_attached :image_file
end
