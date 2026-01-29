class Material < ApplicationRecord
  validates :title, presence: true, length: { maximum: 100 }
  validates :url, presence: true,
                  format: {
                    with: URI::DEFAULT_PARSER.make_regexp(%w[http https]),
                    message: "は正しい形式で入力してください"
                  }
  validates :description, length: { maximum: 5000 }, allow_blank: true

  # カスタムバリデーション: スキームの確認
  validate :url_must_be_http_or_https

  # Ransackで検索可能な属性を定義
  def self.ransackable_attributes(auth_object = nil)
    [ "title" ]
  end

  private

  def url_must_be_http_or_https
    return if url.blank?

    begin
      uri = URI.parse(url)
      unless %w[http https].include?(uri.scheme)
        errors.add(:url, "はhttpまたはhttpsで始まる必要があります")
      end
    rescue URI::InvalidURIError
      errors.add(:url, "の形式が正しくありません")
    end
  end
end
