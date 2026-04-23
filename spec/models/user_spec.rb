require "rails_helper"

RSpec.describe User, type: :model do
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
  end
end
