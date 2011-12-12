uuid = require 'node-uuid'
exports.actions =
  
  # init: (name, cb) ->
    # name = name.trim()
    # @session.setUserId name
    # cb(name)
    
  # getOnlineUsers: (cb)->
    # console.log SS.users.online
#     
    # SS.users.online.now (users)->
      # cb users
  
  sendMessage: (to, message, cb) ->
    @session.channel.list (ch)->
      # console.log "cb: " + ch
    if message.length > 0          
      # console.log "send msg: " + message              
      SS.publish.channel to, 'chatMessage',
        from:@session.user_id
        to:to
        msg:message               
      cb true
    else
      cb false
