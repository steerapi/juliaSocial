# Server-side Code

setInterval (e)->
  exports.actions.updateUsers()
, 10000

exports.actions =
  
  init: (name, cb) ->
    name = name.trim()
    name = SS.shared.util.format name
    @session.setUserId name
    exports.actions.updateUsers()
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
  
  getEtherpadHost:(cb)->
    cb(SS.config.etherpad)
