require "rails_helper"

RSpec.describe Material, type: :model do
  describe "ファクトリ" do
    it "デフォルトで valid なオブジェクトを生成する" do
      expect(build(:material)).to be_valid
    end
  end

  describe "title" do
    it "1 文字で valid（下限・正常系）" do
      material = build(:material, title: "あ")
      expect(material).to be_valid
    end

    it "100 文字ちょうどで valid（境界値・正常系）" do
      material = build(:material, title: "あ" * 100)
      expect(material).to be_valid
    end

    it "101 文字で invalid（境界値超え・異常系）" do
      material = build(:material, title: "あ" * 101)
      expect(material).not_to be_valid
    end

    it "nil で invalid（presence 違反・異常系）" do
      material = build(:material, title: nil)
      expect(material).not_to be_valid
    end

    it "空文字で invalid（presence 違反・異常系）" do
      material = build(:material, title: "")
      expect(material).not_to be_valid
    end
  end

  describe "url" do
    it "http スキームで valid（正常系）" do
      material = build(:material, url: "http://example.com")
      expect(material).to be_valid
    end

    it "https スキーム + path + query で valid（正常系）" do
      material = build(:material, url: "https://example.com/path?q=1")
      expect(material).to be_valid
    end

    it "nil で invalid（presence 違反・異常系）" do
      material = build(:material, url: nil)
      expect(material).not_to be_valid
    end

    it "空文字で invalid（presence 違反・異常系）" do
      material = build(:material, url: "")
      expect(material).not_to be_valid
    end

    it "ftp スキームで invalid（カスタム検証・異常系）" do
      material = build(:material, url: "ftp://example.com")
      material.valid?
      expect(material.errors[:url]).to include(a_string_including("httpまたはhttps"))
    end

    it "URL 形式でない文字列で invalid（format 違反・異常系）" do
      material = build(:material, url: "not a url")
      expect(material).not_to be_valid
    end
  end

  describe "description" do
    it "nil で valid（allow_blank・正常系）" do
      material = build(:material, description: nil)
      expect(material).to be_valid
    end

    it "空文字で valid（allow_blank・正常系）" do
      material = build(:material, description: "")
      expect(material).to be_valid
    end

    it "5000 文字ちょうどで valid（境界値・正常系）" do
      material = build(:material, description: "あ" * 5000)
      expect(material).to be_valid
    end

    it "5001 文字で invalid（境界値超え・異常系）" do
      material = build(:material, description: "あ" * 5001)
      expect(material).not_to be_valid
    end
  end

  describe "アソシエーション" do
    describe "has_many :reviews" do
      it "関連が has_many として定義されている" do
        association = Material.reflect_on_association(:reviews)
        expect(association.macro).to eq :has_many
      end

      it "dependent: :destroy が指定されている" do
        association = Material.reflect_on_association(:reviews)
        expect(association.options[:dependent]).to eq :destroy
      end

      it "Material を destroy すると関連する Review も削除される（挙動）" do
        material = create(:material)
        create(:review, material: material)
        create(:review, material: material)
        expect { material.destroy }.to change { Review.count }.by(-2)
      end
    end
  end

  describe "Ransack 設定" do
    it "ransackable_attributes は title のみを返す" do
      expect(Material.ransackable_attributes).to eq [ "title" ]
    end

    it "title_cont で部分一致検索ができる（正常系）" do
      hit = create(:material, title: "Ruby 入門")
      create(:material, title: "Python 入門")
      result = Material.ransack(title_cont: "Ruby").result
      expect(result).to contain_exactly(hit)
    end

    it "許可されていない属性（description_cont）で検索すると Ransack が例外を投げる" do
      # description は許可属性ではないため、検索条件として作用せず例外で弾かれる
      expect {
        Material.ransack(description_cont: "Ruby").result.load
      }.to raise_error(RuntimeError, /ransackable/)
    end
  end
end
