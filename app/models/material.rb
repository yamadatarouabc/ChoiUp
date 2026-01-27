class Material < ApplicationRecord
  validates :title, presence: true, length: { maximum: 100 }
  validates :url, presence: true,
                  format: {
                    with: URI::DEFAULT_PARSER.make_regexp(%w[http https]),
                    message: "は正しい形式で入力してください"
                  }
  validates :description, length: { maximum: 5000 }, allow_blank: true
end
