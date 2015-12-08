require "../../src/record"

#ENV["DATABASE_URL"] ||= "postgres://postgres@/trail_test"

Trail::Record.connection do
  transaction do
    enable_extension "uuid-ossp"

    create_table :posts, force: true do |t|
      t.string  :title,     null: false, limit: 50
      t.text    :body
      t.boolean :published,                         default: false
      t.integer :views,                  limit: 4,  default: 0
      t.timestamps
    end

    create_table :comments, force: true, id: :uuid, primary_key: :uuid, default: "uuid_generate_v4()" do |t|
      t.integer :post_id
      t.string  :email, null: false
      t.text    :body,  null: false
      t.timestamps
    end

    #add_index :comments, :post_id

    create_table :users, force: true do |t|
      t.string :email, null: false
    end

    create_table :profiles, force: true do |t|
      t.integer :user_id
      t.string  :nickname, null: false
    end

    #add_index :profiles, :user_id
  end
end
