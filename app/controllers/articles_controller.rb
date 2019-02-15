class ArticlesController < ApplicationController
  def show
    @article = Article.find_by(secret_key: params[:id])
    @comments = @article.comments

    if current_user
      @comment = Comment.new
    end
  end

  def new
    @article = Article.new
  end
  
  def create 
    @article = Article.new(article_params)
    if @article.save
      render js: "toastr.success('发表成功！'); window.location.href='/articles/#{@article.secret_key}';"
    else
      render js: "toastr.error('发表失败！')"
    end
  end

  def article_params
    params.require(:article).permit(:title, :content, :user_id)
  end

end
