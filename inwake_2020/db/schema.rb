# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 20200421204303) do

  create_table "alternatives", force: true do |t|
    t.string   "which"
    t.integer  "participants", default: 0
    t.integer  "conversions",  default: 0
    t.text     "experiment"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "alternatives", ["which"], name: "index_alternatives_on_which", using: :btree

  create_table "call_backs", force: true do |t|
    t.string   "name"
    t.string   "phone"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "ip"
  end

  create_table "chat_messages", force: true do |t|
    t.integer "sender_id"
    t.integer "recipient_id"
    t.text    "message"
    t.integer "time",         limit: 8
    t.boolean "delivered"
    t.boolean "removed"
    t.boolean "edited"
    t.boolean "is_file"
    t.string  "file_name"
    t.integer "file_size"
    t.string  "file_path"
  end

  add_index "chat_messages", ["message"], name: "index_chat_messages_on_message", type: :fulltext
  add_index "chat_messages", ["recipient_id"], name: "index_chat_messages_on_recipient_id", using: :btree
  add_index "chat_messages", ["sender_id"], name: "index_chat_messages_on_sender_id", using: :btree
  add_index "chat_messages", ["time"], name: "index_chat_messages_on_time", using: :btree

  create_table "class_types", force: true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "comments", force: true do |t|
    t.text     "text"
    t.integer  "schedule_id"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "comments", ["schedule_id"], name: "index_comments_on_schedule_id", using: :btree
  add_index "comments", ["user_id"], name: "index_comments_on_user_id", using: :btree

  create_table "error_reports", force: true do |t|
    t.text     "description"
    t.text     "messages",    limit: 16777215
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "file"
    t.text     "client_info"
  end

  add_index "error_reports", ["user_id"], name: "index_error_reports_on_user_id", using: :btree

  create_table "homework_files", force: true do |t|
    t.string   "title"
    t.string   "file"
    t.integer  "homework_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id"
  end

  add_index "homework_files", ["homework_id"], name: "index_homework_files_on_homework_id", using: :btree
  add_index "homework_files", ["user_id"], name: "index_homework_files_on_user_id", using: :btree

  create_table "homeworks", force: true do |t|
    t.text     "text"
    t.boolean  "is_done"
    t.integer  "done_time"
    t.integer  "schedule_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "title"
    t.boolean  "by_student"
    t.boolean  "is_moved"
  end

  add_index "homeworks", ["schedule_id"], name: "index_homeworks_on_schedule_id", using: :btree

  create_table "opinions", force: true do |t|
    t.string   "student_name"
    t.string   "progress"
    t.text     "text"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "tutor_id"
    t.string   "fb_link"
    t.string   "vk_link"
    t.integer  "service_id"
  end

  add_index "opinions", ["service_id"], name: "index_opinions_on_service_id", using: :btree
  add_index "opinions", ["tutor_id"], name: "index_opinions_on_tutor_id", using: :btree

  create_table "payments", force: true do |t|
    t.integer  "number"
    t.integer  "user_id"
    t.integer  "schedule_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.float    "amount"
    t.string   "transaction_num"
    t.integer  "pay_time"
    t.string   "payment_system"
    t.string   "ymoney_request_id"
    t.string   "ymoney_error"
    t.text     "payment_entries"
    t.float    "amount_due"
  end

  add_index "payments", ["number"], name: "index_payments_on_number", using: :btree
  add_index "payments", ["schedule_id"], name: "index_payments_on_schedule_id", using: :btree
  add_index "payments", ["user_id"], name: "index_payments_on_user_id", using: :btree

  create_table "reports", force: true do |t|
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "classes_count"
    t.float    "fee"
    t.float    "fee_for_transfer"
    t.integer  "start"
    t.integer  "end"
    t.boolean  "is_executed"
  end

  add_index "reports", ["user_id"], name: "index_reports_on_user_id", using: :btree

  create_table "requests", force: true do |t|
    t.text     "name"
    t.text     "email"
    t.text     "subject"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "phone"
    t.string   "communication"
    t.text     "subjects"
    t.text     "aims"
    t.text     "tutor_traits"
    t.text     "days"
    t.text     "comments"
    t.string   "ip"
  end

  create_table "schedules", force: true do |t|
    t.integer  "time"
    t.integer  "offset"
    t.integer  "duration"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "student_id"
    t.boolean  "free"
    t.boolean  "deferred_payment"
    t.integer  "real_duration"
    t.integer  "start_time"
    t.integer  "end_time"
    t.integer  "remind_time"
    t.integer  "payment_id"
    t.integer  "homework_remind_time"
    t.integer  "state"
    t.integer  "class_type_id"
    t.integer  "payment_remind_time"
    t.float    "saved_cost"
    t.integer  "report_id"
    t.boolean  "lease_paid"
    t.boolean  "group"
  end

  add_index "schedules", ["class_type_id"], name: "index_schedules_on_class_type_id", using: :btree
  add_index "schedules", ["payment_id"], name: "index_schedules_on_payment_id", using: :btree
  add_index "schedules", ["payment_remind_time"], name: "index_schedules_on_payment_remind_time", using: :btree
  add_index "schedules", ["report_id"], name: "index_schedules_on_report_id", using: :btree
  add_index "schedules", ["state"], name: "index_schedules_on_state", using: :btree
  add_index "schedules", ["student_id"], name: "index_schedules_on_student_id", using: :btree
  add_index "schedules", ["time"], name: "index_schedules_on_time", using: :btree
  add_index "schedules", ["user_id"], name: "index_schedules_on_user_id", using: :btree

  create_table "services", force: true do |t|
    t.string   "name"
    t.string   "url"
    t.integer  "services_category_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "text"
    t.integer  "sort_index"
    t.text     "short_text"
    t.string   "name_en"
    t.text     "short_text_en"
    t.text     "text_en"
    t.boolean  "show_on_main"
    t.integer  "classes_mask"
    t.boolean  "advanced_education"
    t.text     "text_right"
    t.text     "text_right_en"
  end

  add_index "services", ["services_category_id"], name: "index_services_on_services_category_id", using: :btree
  add_index "services", ["sort_index"], name: "index_services_on_sort_index", using: :btree
  add_index "services", ["url"], name: "index_services_on_url", unique: true, using: :btree

  create_table "services_categories", force: true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "text"
    t.string   "name_en"
    t.text     "text_en"
    t.string   "icon_class"
  end

  create_table "tutor_classes", force: true do |t|
    t.integer  "user_id"
    t.integer  "class_type_id"
    t.float    "fee"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.float    "cost"
  end

  add_index "tutor_classes", ["class_type_id"], name: "index_tutor_classes_on_class_type_id", using: :btree
  add_index "tutor_classes", ["user_id"], name: "index_tutor_classes_on_user_id", using: :btree

  create_table "tutor_services", force: true do |t|
    t.integer  "tutor_id"
    t.integer  "service_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "recommended"
  end

  add_index "tutor_services", ["service_id"], name: "index_tutor_services_on_service_id", using: :btree
  add_index "tutor_services", ["tutor_id"], name: "index_tutor_services_on_tutor_id", using: :btree

  create_table "tutor_students", force: true do |t|
    t.integer "tutor_id"
    t.integer "student_id"
  end

  add_index "tutor_students", ["student_id"], name: "index_tutor_students_on_student_id", using: :btree
  add_index "tutor_students", ["tutor_id"], name: "index_tutor_students_on_tutor_id", using: :btree

  create_table "tutors", force: true do |t|
    t.string   "name"
    t.text     "job"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "photo"
    t.text     "short_text"
    t.text     "text"
    t.string   "video"
    t.integer  "sort_index"
    t.integer  "user_id"
    t.string   "dialect"
    t.boolean  "russian_language"
    t.text     "languages"
    t.text     "education"
    t.text     "employment"
    t.string   "location"
    t.text     "text_en"
    t.text     "short_text_en"
    t.text     "teach"
    t.boolean  "native_speaker"
    t.boolean  "hidden"
    t.string   "url"
    t.string   "experience"
    t.text     "text_right"
    t.text     "text_right_en"
  end

  add_index "tutors", ["dialect"], name: "index_tutors_on_dialect", using: :btree
  add_index "tutors", ["russian_language"], name: "index_tutors_on_russian_language", using: :btree
  add_index "tutors", ["url"], name: "index_tutors_on_url", unique: true, using: :btree
  add_index "tutors", ["user_id"], name: "index_tutors_on_user_id", using: :btree

  create_table "users", force: true do |t|
    t.string   "email",                     default: "", null: false
    t.string   "encrypted_password",        default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",             default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "role"
    t.integer  "tutor_user_id"
    t.float    "fee"
    t.string   "locale"
    t.boolean  "board"
    t.string   "name"
    t.string   "time_zone"
    t.integer  "roles_mask"
    t.integer  "last_message_notification"
    t.float    "transfer_fee"
    t.boolean  "lease"
    t.string   "lease_ymoney_account"
    t.string   "lease_ymoney_app"
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["name"], name: "index_users_on_name", using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree
  add_index "users", ["tutor_user_id"], name: "index_users_on_tutor_user_id", using: :btree

end
