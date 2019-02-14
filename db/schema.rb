# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2019_02_14_090736) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "article_likes", force: :cascade do |t|
    t.bigint "article_id"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["article_id"], name: "index_article_likes_on_article_id"
    t.index ["user_id"], name: "index_article_likes_on_user_id"
  end

  create_table "articles", force: :cascade do |t|
    t.bigint "user_id"
    t.string "title"
    t.text "content"
    t.integer "comment_count", default: 0
    t.integer "like_count", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "secret_key"
    t.index ["user_id"], name: "index_articles_on_user_id"
  end

  create_table "comments", force: :cascade do |t|
    t.bigint "article_id"
    t.bigint "user_id"
    t.string "content"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["article_id"], name: "index_comments_on_article_id"
    t.index ["user_id"], name: "index_comments_on_user_id"
  end

  create_table "login_logs", force: :cascade do |t|
    t.bigint "user_id"
    t.string "ip"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_login_logs_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name"
    t.string "mobile"
    t.text "description"
    t.string "avatar"
    t.string "password_digest"
    t.string "last_ip"
    t.datetime "last_login_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

end
