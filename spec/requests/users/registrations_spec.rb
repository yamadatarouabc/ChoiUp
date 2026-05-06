require "rails_helper"

RSpec.describe "Users::Registrations", type: :request do
  describe "POST /users（サインアップ）" do
    let(:valid_params) do
      {
        user: {
          email: "newuser@example.com",
          password: "password123",
          password_confirmation: "password123",
          display_name: "新規ユーザー"
        }
      }
    end

    let(:invalid_params) do
      # display_name は presence 必須のため、空にすればバリデーション失敗
      {
        user: {
          email: "newuser@example.com",
          password: "password123",
          password_confirmation: "password123",
          display_name: ""
        }
      }
    end

    context "正常系: 有効なパラメータ" do
      it "User が 1 件増える" do
        expect {
          post user_registration_path, params: valid_params
        }.to change(User, :count).by(1)
      end

      it "root_path にリダイレクトする（after_sign_up_path_for の配線確認）" do
        post user_registration_path, params: valid_params
        expect(response).to redirect_to(root_path)
      end

      it "display_name が保存される（strong parameters の配線確認）" do
        post user_registration_path, params: valid_params
        expect(User.last.display_name).to eq "新規ユーザー"
      end

      it "サインアップ後にログイン状態になる（自動ログインの統合確認）" do
        # サインアップ後、認証必須ページ（new_material_path）にアクセスして
        # ログイン画面に飛ばされないことで、ログイン状態を確認する。
        post user_registration_path, params: valid_params
        get new_material_path
        expect(response).to have_http_status(:ok)
      end
    end

    context "異常系: バリデーション失敗（display_name が空）" do
      it "User が増えない" do
        expect {
          post user_registration_path, params: invalid_params
        }.not_to change(User, :count)
      end

      it "ログイン状態にならない" do
        post user_registration_path, params: invalid_params
        get new_material_path
        # 未ログインなので materials の認可で sign_in にリダイレクトされる
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
