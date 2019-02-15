class SessionsController < ApplicationController
  layout false
  skip_before_action :auto_sign_out

  # 注册
  def new
    @user = User.new
  end

  # 登录
  def sign_in
    @user = User.new
  end

  def create
    if User.find_by(mobile: params[:user][:mobile])
      flash[:error] = '用户已存在！'
      redirect_to new_session_path
    else
      @user = User.create(user_params)
      user_sign_in @user, request.remote_ip
      flash[:info] = '成功登录系统！'
      redirect_to (params[:redirect_to].blank? ? root_path : params[:redirect_to])
    end
  end

  # 用户登陆验证
  def login
    @user = User.find_by(mobile: params[:user][:mobile]).try(:authenticate, params[:user][:password])
    if @user
      user_sign_in @user, request.remote_ip
      set_remember_password
      flash[:info] = '成功登录系统！'
      redirect_to (params[:redirect_to].blank? ? root_path : params[:redirect_to])
    else
      flash[:error] = '密码错误'
      redirect_to login_session_path
    end
  end

  def destroy
    sign_out
    flash[:info] = '成功登出系统！'
    redirect_to root_path
  end

  def set_remember_password
    if params[:remember_password].present?
      cookies.signed[:login_mobile] = params[:mobile]
      cookies.signed[:login_password] = params[:password]
      cookies[:remember_password] = true
    else
      cookies.delete :remember_password
      cookies.delete :login_mobile
      cookies.delete :login_password
    end
  end

  private

  def user_params
    params.require(:user).permit(:name, :mobile, :password)
  end

end
