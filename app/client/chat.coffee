class ChatboxManager
  constructor: ->
    @history = {}
    @newCount = {}
    @box = null
    SS.events.on "chatMessage", (data)=>
      # console.log "data"+data.to
      # console.log "to"+console.log data.to
      if data.to == SS.client.app.user_id
        console.log "TRUE"
        # alert "gotmessage"
        @addMessage(data.from, data.msg)
        if not @box
          @initiate(data.from)
        else if @box?.chatbox("option","id") == data.from
          @box.chatbox("option","boxManager").addMsg data.from, data.msg
        else
          #not currently chatting
          SS.client.app.notify
            title: "New Message"
            message: data.from + " : " + data.msg
          @newCount[data.from]?=0
          @newCount[data.from]++
          $("#chat-id-"+data.from).text "(#{@newCount[data.from]})"
        
    @messageSent = (id,user,msg)=>
      SS.server.chat.sendMessage user, msg, (result)=>
        # alert "gotfeedback: " + result
        @addMessage user, msg if result
        @box.chatbox("option","boxManager").addMsg SS.client.app.user_id, msg
  initiate: (user)->
    @newCount[user]=0
    $("#chat-id-"+user).text "(#{@newCount[user]})"
    @removeBox(@box)
    @box = @addBox(@history[user], user)
  addBox:(history, user)->
    jqel = $('<div/>')
    jqel.chatbox
      id: user
      user: user
      title: user
      hidden: false
      width: 200
      offset: 0
      messageSent: @messageSent
      boxClosed: @boxClosed
    history?.forEach (line)->
      jqel.chatbox("option","boxManager").addMsg line.user, line.msg
    return jqel
    
  boxClosed:(user)->
    @removeBox(@box)
  removeBox:(jqel)->
    jqel?.parent().parent().remove()
  addMessage: (user, msg)->
    
    @history[user]?=[]
    @history[user].push 
      user:user
      msg:msg
    # @box?.parent().parent().remove()
    # @box = addBox(@history[user])
    return

manager = new ChatboxManager()
exports.initiate = (user)->
  manager.initiate user

#     
# do ->
  # boxList = new Array()
  # showList = new Array()
  # nameList = new Array()
  # config =
    # width: 200
    # gap: 8
    # maxBoxes: 5
    # messageSent: (id, dest, msg) ->
      # console.log "Manager"
      # console.log dest
      # console.log showList
      # showList[0].addMsg dest, msg
# 
  # init = (options) ->
    # $.extend config, options
# 
  # delBox = (id) ->
# 
  # getNextOffset = ->
    # (config.width + config.gap) * showList.length
# 
  # boxClosedCallback = (user) ->
    # idx = showList.indexOf(user)
    # unless idx is -1
      # showList.splice idx, 1
      # diff = config.width + config.gap
      # i = idx
# 
      # while i < showList.length
        # offset = $("#chat-" + showList[i]).chatbox("option", "offset")
        # $("#chat-" + showList[i]).chatbox "option", "offset", offset - diff
        # i++
    # else
      # alert "should not happen: " + user
# 
  # addBox = (user) ->
    # idx1 = showList.indexOf(user)
    # idx2 = boxList.indexOf(user)
    # unless idx1 is -1
#       
    # else unless idx2 is -1
      # $("#chat-" + user).chatbox "option", "offset", getNextOffset()
      # manager = $("#chat-" + user).chatbox("option", "boxManager")
      # manager.toggleBox()
      # showList.push user
    # else
      # el = document.createElement("div")
      # el.setAttribute "id", user
      # box = $(el).chatbox
        # id: user
        # user: user
        # title: user
        # hidden: false
        # width: config.width
        # offset: getNextOffset()
        # messageSent: messageSentCallback
        # boxClosed: boxClosedCallback
# 
      # boxList[.push] user
      # showList.push user
      # nameList.push user
# 
  # messageSentCallback = (id, user, msg) ->
    # console.log arguments
    # idx = boxList.indexOf(user)
    # config.messageSent nameList[idx], msg
# 
  # # dispatch = (user, msg) ->
    # # $("#chat-" + user).chatbox("option", "boxManager").addMsg user, msg
# 
  # exports.init = init
  # exports.addBox = addBox
  # exports.delBox = delBox
  # # exports.dispatch = dispatch
# 

