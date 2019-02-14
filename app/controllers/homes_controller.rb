class HomesController < ApplicationController

  def index
    page = params[:page] || 1
    @articles = Article.page(page)
  end
end
