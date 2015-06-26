CONTACT_NAME = 'Raff' -- It can be a part of contacts name
   MESSAGE_COUNT = 50000

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
                     ']] .. m.from.print_name .. [[',
                     ']] .. m.to.print_name .. [[',
                     ']] .. m.text .. [[',
                     ']] .. out .. [[',
                     ']] .. m.date .. [[',
                     ']] .. m.id .. [[',
                        ]]
            if (m.media == nil or m.media == '') then
               sql = sql .. "NULL, NULL, NULL)"
            elseif m.media.type == 'webpage' and not m.media.url == nil then
               sql = sql .. "'1','".. m.media.type .. "', '" .. m.media.url .. "')"
            else
               sql = sql .. "'1','".. m.media.type .. "', NULL)"
            end
            print(m.id)
            -- require 'pl.pretty'.dump(m)
            -- print(sql)
            db:exec(sql)
         end
      end
   end
end

function contacts_cb(extra, success, contacts)
   if success then
      for _,v in pairs(contacts) do
         if string.find(v.print_name, CONTACT_NAME) then
            print(v.print_name)
            get_history(v.print_name, MESSAGE_COUNT, history_cb, history_extra)
         end
      end
   end
end

function on_binlog_replay_end ()
   sqlite3 = require("lsqlite3")
   db = sqlite3.open('db.sqlite3')

   db:exec[[
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

   get_contact_list(contacts_cb, contacts_extra)
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


