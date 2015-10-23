MODE = 'users' -- 'history' or 'users'
CONTACT_NAME = 'Dmi' -- It can be a part of contacts name
MESSAGE_COUNT = 500
DATABASE_FILE = 'db.sqlite3'

function history_cb(extra, success, history)
   if success then
      for _,m in pairs(history) do
         if not m.service then -- Ignore Telegram service messages
            local out = m.out and 1 or 0 -- Cast boolean to integer
            if m.text == nil then -- No nil value
               m.text = ''
            end
            local sql = [[
                  INSERT INTO messages
                  (`from`, `to`, `text`, `out`, `date`, `message_id`, `media`, `media_type`,`url`)
                  VALUES (
                     ']] .. db:escape(m.from.print_name) .. [[',
                     ']] .. db:escape(m.to.print_name) .. [[',
                     ']] .. db:escape(m.text) .. [[',
                     ']] .. out .. [[',
                     ']] .. m.date .. [[',
                     ']] .. m.id .. [[',
                        ]]
            if (m.media == nil or m.media == '') then
               sql = sql .. "NULL, NULL, NULL)"
            elseif m.media.type == 'webpage' and m.media.url ~= nil then
               sql = sql .. "'1','".. m.media.type .. "', '" .. m.media.url .. "')"
            else
               sql = sql .. "'1','".. m.media.type .. "', NULL)"
            end
            print(m.id)
            --require 'pl.pretty'.dump(m)
            -- print(sql)
            res = db:execute(sql)
            -- print(heh)
         end
      end
      print("done")
   end
end

function user_cb(extra, success, user)
   if success and user.print_name ~= 'deleted' then
      if user.phone == nil then
         user.phone = ''
      end
      if user.username == nil then
         user.username = ''
      end
      local sql = [[
            INSERT INTO users
            (`id`, `name`, `username`, `phone`)
            VALUES (
               ']] .. user.id .. [[',
               ']] .. db:escape(user.print_name) .. [[',
               ']] .. user.username .. [[',
               ']] .. user.phone .. [['
               );
                  ]]
      -- print(sql)
      res = db:execute(sql)
      -- print(res)
   end
end

function dialogs_cb(extra, success, dialog)
   if success then
      for _,d in pairs(dialog) do
         v = d.peer
         if v.print_name ~= nil and string.find(v.print_name, CONTACT_NAME) then
            print(v.print_name)
            if (v.type == 'user') then
               user_info(v.print_name, user_cb, history_extra)
            else
               chat_info(v.print_name, user_cb, history_extra)
            end
            if MODE == 'history' then
               get_history(v.print_name, MESSAGE_COUNT, history_cb, history_extra)
            end
         end
      end
   end
end

function on_binlog_replay_end ()
   sqlite3 = require("luasql.sqlite3")
   --db = sqlite3.open(DATABASE_FILE)
   driver = sqlite3.sqlite3()
   db = driver:connect(DATABASE_FILE)

   res = db:execute[[
         CREATE TABLE messages (
            `id` INTEGER PRIMARY KEY,
            `from` TEXT,
            `to` TEXT,
            `text` TEXT,
            `out` INTEGER,
            `date` INTEGER,
            `message_id` INTEGER,
            `media` TEXT,
            `media_type` TEXT,
            `url` TEXT
                               );
          ]]

   res = db:execute[[
         CREATE TABLE users (
            `id` INTEGER PRIMARY KEY,
            `name` TEXT,
            `username` TEXT,
            `phone` TEXT
                               );
          ]]

   res = get_dialog_list(dialogs_cb, contacts_extra)
end

function on_msg_receive (msg)
end

function on_our_id (id)
end

function on_secret_chat_created (peer)
end

function on_user_update (user)
end

function on_chat_update (user)
end

function on_get_difference_end ()
end
