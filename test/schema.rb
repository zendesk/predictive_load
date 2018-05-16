ActiveRecord::Schema.verbose = false

ActiveRecord::Schema.define(:version => 1) do
  drop_table(:users)    rescue nil
  drop_table(:emails)   rescue nil
  drop_table(:photos)   rescue nil
  drop_table(:topics)   rescue nil
  drop_table(:comments) rescue nil
  drop_table(:emails_users) rescue nil

  create_table(:users) do |t|
    t.string   :name,    :null => false
  end

  create_table(:photos) do |t|
    t.integer  :user_id, :null => false
  end

  create_table(:emails_users) do |t|
    t.integer :user_id
    t.integer :email_id
  end

  create_table(:emails) do |t|
  end

  create_table(:topics) do |t|
    t.string   :title,   :null => false
  end

  create_table(:comments) do |t|
    t.string   :body,     :null => false
    t.integer  :topic_id, :null => false
    t.integer  :user_id,  :null => true
    t.boolean  :public,   :null => false, :default => true
    t.timestamps(null: false)
  end

  create_table(:attachments) do |t|
    t.string   :source_type, :null => false
    t.integer  :source_id,   :null => false
    t.boolean  :public, :default => true,   :null => false
    t.timestamps(null: false)
  end
end
