class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  enum :role, { general: 0, admin: 100 }

  validates :display_name, presence: true, length: { maximum: 50 }

  has_many :reviews, dependent: :destroy
end
