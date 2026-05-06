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

  describe "email" do
    it "一般的なメール形式で valid（正常系）" do
      user = build(:user, email: "valid@example.com")
      expect(user).to be_valid
    end

    it "nil で invalid（presence 違反・異常系）" do
      user = build(:user, email: nil)
      expect(user).not_to be_valid
    end

    it "空文字で invalid（presence 違反・異常系）" do
      user = build(:user, email: "")
      expect(user).not_to be_valid
    end

    it "@ を含まない文字列で invalid（format 違反・異常系）" do
      user = build(:user, email: "not-an-email")
      expect(user).not_to be_valid
    end

    it "ローカル部のみで invalid（format 違反・異常系）" do
      user = build(:user, email: "foo@")
      expect(user).not_to be_valid
    end

    it "既存ユーザーと同じ email で invalid（一意性違反・異常系）" do
      create(:user, email: "dup@example.com")
      user_with_same_email = build(:user, email: "dup@example.com")
      expect(user_with_same_email).not_to be_valid
    end

    it "大文字小文字違いの同 email で invalid（case_insensitive_keys・異常系）" do
      # Devise の case_insensitive_keys = [:email] により大文字小文字を区別せず一意性を判定する
      create(:user, email: "case@example.com")
      user_with_uppercase_email = build(:user, email: "CASE@example.com")
      expect(user_with_uppercase_email).not_to be_valid
    end
  end

  describe "password" do
    # Devise validatable + config.password_length = 6..128 による境界値
    it "6 文字ちょうどで valid（境界値・正常系）" do
      user = build(:user, password: "a" * 6, password_confirmation: "a" * 6)
      expect(user).to be_valid
    end

    it "5 文字で invalid（境界値超え・異常系）" do
      user = build(:user, password: "a" * 5, password_confirmation: "a" * 5)
      expect(user).not_to be_valid
    end

    it "128 文字ちょうどで valid（境界値・正常系）" do
      user = build(:user, password: "a" * 128, password_confirmation: "a" * 128)
      expect(user).to be_valid
    end

    it "129 文字で invalid（境界値超え・異常系）" do
      user = build(:user, password: "a" * 129, password_confirmation: "a" * 129)
      expect(user).not_to be_valid
    end

    it "新規作成時に nil だと invalid（presence 違反・異常系）" do
      user = build(:user, password: nil, password_confirmation: nil)
      expect(user).not_to be_valid
    end
  end

  describe "Devise モジュール構成" do
    # 認証に関する設定の明文化。誤って外すと auth まわりの挙動が変わるため、構成自体を担保する。
    it ":database_authenticatable, :registerable, :recoverable, :rememberable, :validatable がすべて有効である" do
      expect(User.devise_modules).to include(
        :database_authenticatable,
        :registerable,
        :recoverable,
        :rememberable,
        :validatable
      )
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
