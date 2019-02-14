class ArticlesController < ApplicationController
  def show
    @article = Article.find_by(secret_key: params[:id])
    @comments = @article.comments

    if current_user
      @comment = Comment.new
    end
  end
end
