module MaterialsHelper
  def safe_material_url(material)
    # http/https以外のスキームを除外
    uri = URI.parse(material.url)
    return material.url if %w[http https].include?(uri.scheme)

    # 万が一の場合は安全なデフォルトURL
    root_path
  rescue URI::InvalidURIError
    root_path
  end
end
