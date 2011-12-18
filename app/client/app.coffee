# Client-side Code

# Bind to socket events
SS.socket.on 'disconnect', ->  $('#message').text('SocketStream server is down :-(')
SS.socket.on 'reconnect', ->   $('#message').text('SocketStream server is up :-)')

exports.user_id = null

init_chat = ->

updateUserList = (users)->
  $("#people-head").empty()
  $("#people-list").empty()
  $("#people-head").text users.length+" users online"
  idx = users.indexOf exports.user_id
  users.splice idx,1
  users.forEach (user)->
    obj = $('#templates-username').mustache(name:user)
    obj.find("#count").attr "id","chat-id-"+user
    obj.find("a").click (e)->
      SS.client.chat.initiate(user)
      e.preventDefault()
    obj.appendTo("#people-list")

jqconsole = null
      
jqconsole_welcome = ->
  $ ->
    header = "Welcome to Julia Social\n"
    jqconsole = $("#terminal-console").jqconsole(header, "name please: ")
    handler = (command) ->
      if command
        SS.server.app.init command, (name)->
          SS.events.on "updateUser", (users)->
            updateUserList(users)
          exports.user_id = name
          SS.server.app.subscribe name, ->
          jqconsole_init(name)
          SS.server.app.getOnlineUsers (users)->
            updateUserList(users)
      jqconsole.Prompt true, handler, (command)->
        return false
    handler()


jqconsole_init = (name)->
  $ ->
    chatmode = false
    $("#tool-bar").show()
    set_outer_height "#terminal-console", $(window).height()-$("#tool-bar").height()
    init_editor(false)
    $("#terminal-console").empty()
    header = "Welcome to Julia Social.\nYour name is #{name}.\n"
    jqconsole = $("#terminal-console").jqconsole(header, "#{name}> ")
    
    jqconsole.RegisterShortcut "Z", ->
      jqconsole.AbortPrompt()
      handler()
  
    jqconsole.RegisterShortcut "A", ->
      jqconsole.MoveToStart()
      handler()

    jqconsole.RegisterShortcut "Q", ->
      if chatmode
        chatmode = false
        jqconsole.$prompt_label.text("#{name}> ")
        jqconsole.prompt_label_main = "#{name}> "
      else
        chatmode = true
        jqconsole.$prompt_label.text("[CHAT] #{name}> ")
        jqconsole.prompt_label_main = "[CHAT] #{name}> "
      handler()
  
    jqconsole.RegisterShortcut "W", ->
      handler()
    
    jqconsole.RegisterShortcut "E", ->
      jqconsole.MoveToEnd()
      handler()
  
    jqconsole.RegisterMatching "{", "}", "brace"
    jqconsole.RegisterMatching "(", ")", "paran"
    jqconsole.RegisterMatching "[", "]", "bracket"
    
    SS.events.on "juliaMessage", (data)->
      command = data.cmd
      result = data.result
      from = data.from
      command.split(/[\n|\r]/).forEach (line)->
        if /end/.test line
          line = line.trim()
        jqconsole.Write "[#{from}] " + line + "\n", "", false
      result?.split(/[\n|\r]/).forEach (line)->
        jqconsole.Write "[#{from}] ==> " + line + "\n"
    chathandler = (command)->
      console.log "CMD: "+command
      # jqconsole.Prompt true, chathandler, (command)->
        # false
    handler = (command) ->
      if command
        if chatmode
          SS.server.julia.chat command, (data)->
        else
          SS.server.julia.execute 0, command, (data)->
          
      jqconsole.Prompt true, handler, (command)->
        cmds = command.split(/\n/)
        first_line = cmds[0]
        last_line = cmds[-1..][0]
        
        if /end/.test(last_line) or not /for|while|function|try|if/.test(first_line)
          return false

        if /for|while|function|try|if/.test(last_line)
          return 1
        else
          return 0
  
    handler()

set_outer_height = (selector, height) ->
  $(selector).height 1
  $(selector).height height + 1 - $(selector).outerHeight(true)
  
julia = ->
  set_column_heights = ->
    set_outer_height "#left-column", $(window).height()
    set_outer_height "#right-column", $(window).height()
    set_outer_height "#terminal-form", $(window).height()
    set_outer_height "#terminal-console", $(window).height()
    set_outer_height "#chat-column", $(window).height()
  $(document).ready set_column_heights
  $(window).resize set_column_heights

  MSG_INPUT_NULL = 0
  MSG_INPUT_START = 1
  MSG_INPUT_POLL = 2
  MSG_INPUT_EVAL = 3
  MSG_OUTPUT_NULL = 0
  MSG_OUTPUT_READY = 1
  MSG_OUTPUT_MESSAGE = 2
  MSG_OUTPUT_OTHER = 3
  MSG_OUTPUT_FATAL_ERROR = 4
  MSG_OUTPUT_PARSE_ERROR = 5
  MSG_OUTPUT_PARSE_INCOMPLETE = 6
  MSG_OUTPUT_PARSE_COMPLETE = 7
  MSG_OUTPUT_EVAL_RESULT = 8
  MSG_OUTPUT_EVAL_ERROR = 9
  MSG_OUTPUT_PLOT = 10

  outbox_queue = []
  
  set_input_width = ->
  $("#terminal-input").width $("#terminal").width() - $("#prompt").width() - 1
  escape_html = (str) ->
    str.replace(/&/g, "&").replace(/</g, "<").replace(/>/g, ">").replace(RegExp(" ", "g"), " ").replace(/\\t/g, "    ").replace /\n/g, "<br />"
  add_to_terminal = (data) ->
    $("#terminal").append data
    set_input_width()
    $("#terminal-form").prop "scrollTop", $("#terminal-form").prop("scrollHeight")
  init_session = ->
    outbox_queue.push [ MSG_INPUT_START ]
    process_outbox()
  poll = ->
    outbox_queue.push [ MSG_INPUT_POLL ]
    process_outbox()
  process_outbox = ->
    unless waiting_for_response
      if outbox_queue.length > 0
        waiting_for_response = true
        $.post "http://localhost:1441/repl.scgi",
          request: $.toJSON(outbox_queue)
        , callback, "json"
      outbox_queue = []
  process_inbox = ->
    for id of inbox_queue
      inbox_queue[id][0] is MSG_OUTPUT_NULL
      if inbox_queue[id][0] is MSG_OUTPUT_READY
        $("#terminal").html ""
        $("#prompt").show()
        $("#terminal-input").removeAttr "disabled"
        $("#terminal-input").show()
        $("#terminal-input").focus()
        set_input_width()
      add_to_terminal "<span class=\"message\">" + escape_html(inbox_queue[id][1]) + "</span><br /><br />"  if inbox_queue[id][0] is MSG_OUTPUT_MESSAGE
      add_to_terminal escape_html(inbox_queue[id][1])  if inbox_queue[id][0] is MSG_OUTPUT_OTHER
      if inbox_queue[id][0] is MSG_OUTPUT_FATAL_ERROR
        add_to_terminal "<span class=\"error\">" + escape_html(inbox_queue[id][1]) + "</span><br /><br />"
        dead = true
        inbox_queue = []
        outbox_queue = []
        break
      if inbox_queue[id][0] is MSG_OUTPUT_PARSE_ERROR
        input = $("#terminal-input").val()
        input_history.push input  unless input.replace(/^\\s+|\s+$/g, "") is ""
        input_history = input_history.slice(input_history.length - input_history_size)  if input_history.length > input_history_size
        input_history_current = input_history.slice(0)
        input_history_current.push ""
        input_history_id = input_history_current.length - 1
        add_to_terminal "<span class=\"prompt\">julia> </span>" + escape_html(input.replace(/\n/g, "\n       ")) + "<br />"
        add_to_terminal "<span class=\"error\">" + escape_html(inbox_queue[id][1]) + "</span><br /><br />"
        $("#terminal-input").val ""
        $("#terminal-input").removeAttr "disabled"
        $("#terminal-input").focus()
      if inbox_queue[id][0] is MSG_OUTPUT_PARSE_INCOMPLETE
        $("#terminal-input").removeAttr "disabled"
        $("#terminal-input").focus()
        $("#terminal-input").newline_at_caret()
      if inbox_queue[id][0] is MSG_OUTPUT_PARSE_COMPLETE
        input = $("#terminal-input").val()
        input_history.push input  unless input.replace(/^\\s+|\s+$/g, "") is ""
        input_history = input_history.slice(input_history.length - input_history_size)  if input_history.length > input_history_size
        input_history_current = input_history.slice(0)
        input_history_current.push ""
        input_history_id = input_history_current.length - 1
        add_to_terminal "<span class=\"prompt\">julia> </span>" + escape_html(input.replace(/\n/g, "\n       ")) + "<br />"
        $("#terminal-input").val ""
        $("#prompt").hide()
      if inbox_queue[id][0] is MSG_OUTPUT_EVAL_RESULT
        if $.trim(inbox_queue[id][1]) is ""
          add_to_terminal "<br />"
        else
          add_to_terminal escape_html(inbox_queue[id][1]) + "<br /><br />"
        $("#prompt").show()
        $("#terminal-input").removeAttr "disabled"
        $("#terminal-input").focus()
      if inbox_queue[id][0] is MSG_OUTPUT_EVAL_ERROR
        add_to_terminal "<span class=\"error\">" + escape_html(inbox_queue[id][1]) + "</span><br /><br />"
        $("#prompt").show()
        $("#terminal-input").removeAttr "disabled"
        $("#terminal-input").focus()
      if inbox_queue[id][0] is MSG_OUTPUT_PLOT
        if inbox_queue[id][1] is "line"
          x_data = eval(inbox_queue[id][2])
          y_data = eval(inbox_queue[id][3])
          x_min = eval(inbox_queue[id][4])
          x_max = eval(inbox_queue[id][5])
          y_min = eval(inbox_queue[id][6])
          y_max = eval(inbox_queue[id][7])
          data = d3.range(x_data.length).map((i) ->
            x: x_data[i]
            y: y_data[i]
          )
          w = 450
          h = 275
          p = 40
          x = d3.scale.linear().domain([ x_min, x_max ]).range([ 0, w ])
          y = d3.scale.linear().domain([ y_min - (y_max - y_min) * 0.1, y_max + (y_max - y_min) * 0.1 ]).range([ h, 0 ])
          xticks = x.ticks(8)
          yticks = y.ticks(8)
          vis = d3.select("#terminal").append("svg").data([ data ]).attr("width", w + p * 2).attr("height", h + p * 2).append("g").attr("transform", "translate(" + String(p) + "," + String(p) + ")")
          vrules = vis.selectAll("g.vrule").data(xticks).enter().append("g").attr("class", "vrule")
          hrules = vis.selectAll("g.hrule").data(yticks).enter().append("g").attr("class", "hrule")
          vrules.filter((d) ->
            d isnt 0
          ).append("line").attr("x1", x).attr("x2", x).attr("y1", 0).attr "y2", h - 1
          hrules.filter((d) ->
            d isnt 0
          ).append("line").attr("y1", y).attr("y2", y).attr("x1", 0).attr "x2", w + 1
          vrules.append("text").attr("x", x).attr("y", h + 10).attr("dy", ".71em").attr("text-anchor", "middle").attr("fill", "#444444").text x.tickFormat(10)
          hrules.append("text").attr("y", y).attr("x", -5).attr("dy", ".35em").attr("text-anchor", "end").attr("fill", "#444444").text y.tickFormat(10)
          vrules2 = vis.selectAll("g.vrule2").data(xticks).enter().append("g").attr("class", "vrule2")
          hrules2 = vis.selectAll("g.hrule2").data(yticks).enter().append("g").attr("class", "hrule2")
          vrules2.filter((d) ->
            d is 0
          ).append("line").attr("class", "axis").attr("x1", x).attr("x2", x).attr("y1", 0).attr "y2", h - 1
          hrules2.filter((d) ->
            d is 0
          ).append("line").attr("class", "axis").attr("y1", y).attr("y2", y).attr("x1", 0).attr "x2", w + 1
          vis.append("path").attr("class", "line").attr "d", d3.svg.line().x((d) ->
            x d.x
          ).y((d) ->
            y d.y
          )
          add_to_terminal "<br />"
          $("#terminal-form").prop "scrollTop", $("#terminal-form").prop("scrollHeight")
    inbox_queue = []
  callback = (data, textStatus, jqXHR) ->
    return  if dead
    waiting_for_response = false
    inbox_queue = inbox_queue.concat(data)
    process_inbox()
    process_outbox()
    setTimeout poll, poll_interval
  indent_str = "    "
  poll_interval = 200
  waiting_for_response = false
  input_history = []
  input_history_current = [ "" ]
  input_history_id = 0
  input_history_size = 100
  inbox_queue = []
  dead = false
  $(window).resize set_input_width
  jQuery.fn.extend
    insert_at_caret: (str) ->
      @each (i) ->
        if document.selection
          @focus()
          sel = document.selection.createRange()
          sel.text = str
          @focus()
        else if @selectionStart or @selectionStart is "0"
          start_pos = @selectionStart
          end_pos = @selectionEnd
          scroll_top = @scrollTop
          @value = @value.substring(0, start_pos) + str + @value.substring(end_pos, @value.length)
          @focus()
          @selectionStart = start_pos + str.length
          @selectionEnd = start_pos + str.length
          @scrollTop = scroll_top
        else
          @value += str
          @focus()
  
    backspace_at_caret: ->
      @each (i) ->
        if document.selection
          @focus()
          sel = document.selection.createRange()
          sel.text = ""
          @focus()
        else if @selectionStart or @selectionStart is "0"
          start_pos = @selectionStart
          end_pos = @selectionEnd
          scroll_top = @scrollTop
          if start_pos is end_pos
            if start_pos > 0
              if start_pos > indent_str.length - 1
                if @value.substring(start_pos - indent_str.length, start_pos) is indent_str
                  @value = @value.substring(0, start_pos - indent_str.length) + @value.substring(end_pos, @value.length)
                  @selectionStart = start_pos - indent_str.length
                  @selectionEnd = start_pos - indent_str.length
                else
                  @value = @value.substring(0, start_pos - 1) + @value.substring(end_pos, @value.length)
                  @selectionStart = start_pos - 1
                  @selectionEnd = start_pos - 1
              else
                @value = @value.substring(0, start_pos - 1) + @value.substring(end_pos, @value.length)
                @selectionStart = start_pos - 1
                @selectionEnd = start_pos - 1
          else
            @value = @value.substring(0, start_pos) + @value.substring(end_pos, @value.length)
            @selectionStart = start_pos
            @selectionEnd = start_pos
          @focus()
          @scrollTop = scroll_top
  
    newline_at_caret: ->
      @each (i) ->
        indent = ""
        if @selectionStart or @selectionStart is "0"
          start_pos = @selectionStart
          while start_pos > 0
            break  if @value[start_pos - 1] is "\\n"
            start_pos -= 1
          end_pos = start_pos
          while end_pos < @value.length
            break  unless @value[end_pos] is " "
            end_pos += 1
          indent = @value.substring(start_pos, end_pos)
        $(this).insert_at_caret "\\n" + indent
  
  $(document).ready ->
    $("#terminal-input").autoResize
      animate: false
      maxHeight: 1000
      onAfterResize: ->
        setTimeout (->
          $("#terminal-form").prop "scrollTop", $("#terminal-form").prop("scrollHeight")
        ), 100
        set_input_width()
  
    $("#terminal-input").val ""
    mouse_x = undefined
    mouse_y = undefined
    $(window).mousedown (evt) ->
      mouse_x = evt.pageX
      mouse_y = evt.pageY
  
    $("#terminal-form").click (evt) ->
      $("#terminal-input").focus()  if (mouse_x - evt.pageX) * (mouse_x - evt.pageX) + (mouse_y is evt.pageY) * (mouse_y is evt.pageY) < 4
  
    $("#terminal-input").keydown (evt) ->
      switch evt.keyCode
        when 8
          unless $("#terminal-input").attr("disabled")
            $("#terminal-input").backspace_at_caret()
            $("#terminal-form").prop "scrollTop", $("#terminal-form").prop("scrollHeight")
          false
        when 9
          unless $("#terminal-input").attr("disabled")
            $("#terminal-input").insert_at_caret indent_str
            $("#terminal-form").prop "scrollTop", $("#terminal-form").prop("scrollHeight")
          false
        when 38
          unless $("#terminal-input").attr("disabled")
            input_history_current[input_history_id] = $("#terminal-input").val()
            input_history_id -= 1
            input_history_id = 0  if input_history_id < 0
            $("#terminal-input").val input_history_current[input_history_id]
            $("#terminal-form").prop "scrollTop", $("#terminal-form").prop("scrollHeight")
          false
        when 40
          unless $("#terminal-input").attr("disabled")
            input_history_current[input_history_id] = $("#terminal-input").val()
            input_history_id += 1
            input_history_id = input_history_current.length - 1  if input_history_id > input_history_current.length - 1
            $("#terminal-input").val input_history_current[input_history_id]
            $("#terminal-form").prop "scrollTop", $("#terminal-form").prop("scrollHeight")
          false
        when 13
          unless $("#terminal-input").attr("disabled")
            $("#terminal-input").attr "disabled", "disabled"
            input = $("#terminal-input").val()
            outbox_queue.push [ MSG_INPUT_EVAL, input ]
            process_outbox()
          false
  
    $("#terminal-form").prop "scrollTop", $("#terminal-form").prop("scrollHeight")
    # init_session()
  
showMainScreen = ->
  $("#loginscreen").hide()
  $("#mainscreen").show()
  params =
    name: "Hello"
    type: "chat"
    isPrivate: true
  # SS.server.app.logout()
  SS.server.app.currentUser (user)->
    view =
      username: user
    $('#templates-userbar').mustache(view).appendTo("#user-bar")
    $("#logoutBtn").click (e)->
      SS.server.app.logout()
      showLoginScreen()
  renderChannellist = (channels)->
    channels = channels.sort()
    view =
      items: channels
    tag = $("<div/>",
      id:"peoplelist-container"
      style:"display:none;"
    )
    $('#templates-channellist').mustache(view).appendTo("#channellist")
      
    $('#channellist').find('li').hover (e)->
      $(this).toggleClass("active")
    $('#channellist').find('li').click (e)->
      console.log $(this)
      # console.log e.currentTarget
    
  renderUserlist = (users)->
    users = users.sort()
    view =
      items: users
    tag = $("<div/>",
      id:"peoplelist-container"
      style:"display:none;"
    )
    $('#templates-peoplelist').mustache(view).appendTo("#userlist")
    $('#userlist').find('li').hover (e)->
      $(this).toggleClass("active")
    $('#userlist').find('li').click (e)->
      console.log $(this)
      
  SS.server.app.listUser (users)->
    renderUserlist(users)
  SS.server.app.listChannel (channels)->
    renderChannellist(channels)
  SS.events.on 'channellistUpdate', (channels)->
    renderChannellist(channels)
  SS.events.on 'userlistUpdate', (users)->
    renderUserlist(users)
  $('#createRoom').submit ->
    params = 
      name: $('#createRoom').find('#roomname').val()
    SS.server.app.createChannel params,(data)->
      console.log data
    view =
      items: ["A","B","C","D"]
    tag = $("<div/>",
      id:"peoplelist-container"
      style:"display:none;"
    )
    $('#templates-peoplelist').mustache(view).appendTo(tag)
    $("#main").window
      title: params.name
      content: tag
      showFooter: false
      checkBoundary: true
    false

init_editor = (show)->
  SS.server.app.getEtherpadHost (host)->
    $(->
      thePad = $('#pad')
      thePad.pad
        padId:'julia-general'
        showChat:'false'
        showControls:'true'
        userName:exports.user_id
        host:host
      if show
        thePad.show()
      else
        thePad.hide()
      $('#epframepad').attr 'style', 'width:100%'
      set_outer_height "#epframepad", $(window).height()-$("#tool-bar").height()-5
    )
  
thePad = undefined
# This method is called automatically when the websocket connection is established. Do not rename/delete
exports.init = ->
  # args = window.location.split("?")
  # if args.length>1
  # args = args[args.length-1]
  # args.split("=")
  #   
  jqconsole_welcome()
  julia()
  $(->
    SS.events.on "restarting", ->
      exports.notify 
        title: "Restarting Julia"
        message: "Just a moment..."
    SS.events.on "restart", ->
      exports.notify 
        title: ""
        message: "Julia session was restarted."
    $("#restart_editor").button().click (e)->
      init_editor(true)
    $("#restart").button().click (e)->
      SS.server.julia.restart (cb)->
    $("#run").button().click (e)->
      $("#prompt").click()
      jqconsole?.Write "[#{exports.user_id}] " + "Running code from the editor..." + "\n", "", false
      exports.notify 
        title: "Running the code"
        message: "Just a moment..."
      $('#pad').pad 'getContents':'padContent', (data)->
        data = data.trim()
        if data
          SS.server.julia.execute 0, data, (result)->
            console.log result
        else
          exports.notify  
            title: "Error"
            message: "The code is blank."
  )
  $("#prompt").click (e)->
    $("#prompt").addClass "current-page"
    $("#editor").removeClass "current-page"
    $('#terminal-console').show()
    $('#pad').hide()
  $("#editor").click (e)->
    if exports.user_id
      set_outer_height "#pad", $(window).height()-$("#tool-bar").height()
      $("#editor").addClass "current-page"
      $("#prompt").removeClass "current-page"
      $('#terminal-console').hide()

      $('#epframepad').attr 'style', 'width:100%'
      set_outer_height "#epframepad", $(window).height()-$("#tool-bar").height()-5
      $('#run').show()
      $('#restart_editor').show()
      $('#pad').show()
    else
      exports.notify
        title: ""
        message: "You have to sign in first"
        
exports.notify = (view)->
  $("#templates-notice").mustache(view).purr 
    usingTransparentPNG: true
    fadeInSpeed: 500
    fadeOutSpeed: 1000
    removeTimer: 1000  
      # $("<div/>").append(obj).purr usingTransparentPNG: true
      # false
      # $("<div/>").append('You have to sign in first.').purr

  # setTimeout ->
    # $('#pad').pad 'getContents':'padContent', (data)->
      # alert(data)
  # , 5000
  
  # SS.server.app.init (response) ->
    
    # jqconsole_init()
    