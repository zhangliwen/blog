class CommentsController < ApplicationController
  before_action :login_required

  def create
    @comment = Comment.new(comment_params)

    if @comment.save
      render js: "toastr.success('发表成功！'); window.location.reload();"
    else
      render js: "toastr.error('发表失败！')"
    end
  end

  def comment_params
    params.require(:comment).permit(:article_id, :content, :user_id)
  end
end
