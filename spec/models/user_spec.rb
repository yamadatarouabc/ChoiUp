require "rails_helper"

RSpec.describe User, type: :model do
  describe "ファクトリ" do
    it "デフォルトで valid なオブジェクトを生成する" do
      expect(build(:user)).to be_valid
    end
  end

  describe "display_name" do
    it "50 文字ちょうどなら valid（境界値・正常系）" do
      user = build(:user, display_name: "あ" * 50)
      expect(user).to be_valid
    end

    it "51 文字だと invalid（境界値超え・異常系）" do
      user = build(:user, display_name: "あ" * 51)
      expect(user).not_to be_valid
    end

    it "nil だと invalid（presence 違反・異常系）" do
      user = build(:user, display_name: nil)
      expect(user).not_to be_valid
    end

    it "空文字だと invalid（presence 違反・異常系）" do
      user = build(:user, display_name: "")
      expect(user).not_to be_valid
    end
  end

  describe "アソシエーション" do
    describe "has_many :reviews" do
      # reflect_on_association は関連定義の情報オブジェクトを返す。
      # .macro で関連種別、.options で has_many に渡したオプションを取得できる。
      it "関連が has_many として定義されている" do
        association = User.reflect_on_association(:reviews)
        expect(association.macro).to eq :has_many
      end

      it "dependent: :destroy が指定されている" do
        association = User.reflect_on_association(:reviews)
        expect(association.options[:dependent]).to eq :destroy
      end

      it "User を destroy すると関連する Review も削除される（挙動）" do
        user = create(:user)
        create(:review, user: user)
        create(:review, user: user)
        expect { user.destroy }.to change { Review.count }.by(-2)
      end
    end
  end
end
