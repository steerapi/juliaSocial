# Server-side Code

uuid = require 'node-uuid'

# setInterval (e)->
  # exports.actions.updateUsers()
# , 5000

exports.actions =
  
  init: (name, cb) ->
    name = name.trim()
    name = SS.shared.util.format name
    @session.setUserId name
    cb(name)
    
  getOnlineUsers: (cb)->
    SS.users.online.now (users)->
      users.sort()
      cb users

  subscribe:(name,cb)->
    @session.channel.subscribe(name)
    cb true
  
  updateUsers:(cb)->
    exports.actions.getOnlineUsers (users)->
      SS.publish.broadcast 'updateUser', users 
    
