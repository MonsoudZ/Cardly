module Admin
  class UsersController < BaseController
    before_action :set_user, only: [ :show, :edit, :update, :destroy, :toggle_admin ]

    def index
      @users = User.order(created_at: :desc)

      # Search
      if params[:search].present?
        search = "%#{params[:search]}%"
        @users = @users.where("email ILIKE ? OR name ILIKE ?", search, search)
      end

      # Filter by admin status
      if params[:admin].present?
        @users = @users.where(admin: params[:admin] == "true")
      end

      @users = @users.page(params[:page]).per(25)
    end

    def show
      @gift_cards = @user.gift_cards.includes(:brand).order(created_at: :desc).limit(10)
      @listings = @user.listings.includes(gift_card: :brand).order(created_at: :desc).limit(10)
      @transactions = Transaction.involving_user(@user)
                                  .includes(:buyer, :seller, listing: { gift_card: :brand })
                                  .order(created_at: :desc)
                                  .limit(10)
    end

    def edit
    end

    def update
      if @user.update(user_params)
        redirect_to admin_user_path(@user), notice: "User updated successfully."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      if @user == current_user
        redirect_to admin_users_path, alert: "You cannot delete yourself."
        return
      end

      @user.destroy
      redirect_to admin_users_path, notice: "User deleted successfully."
    end

    def toggle_admin
      if @user == current_user
        redirect_to admin_users_path, alert: "You cannot change your own admin status."
        return
      end

      @user.update(admin: !@user.admin?)
      status = @user.admin? ? "granted admin access" : "removed admin access"
      redirect_to admin_user_path(@user), notice: "User #{status}."
    end

    private

    def set_user
      @user = User.find(params[:id])
    end

    def user_params
      params.require(:user).permit(:name, :email)
    end
  end
end
