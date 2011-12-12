util = require("util")
spawn = require("child_process").spawn
events = require('events')  

juliaPrompt = "julia> "
detectPrompt = (data)->
  data.indexOf(juliaPrompt) != -1
stripPrompt = (data)->
  data.replace(juliaPrompt,"")
  
class JuliaSession extends events.EventEmitter
  constructor:->
    @julia = spawn("/Users/Au/juliaSocial/julia/julia", [])
    @callback = {}
    @queue = []
    answer = ""
    @ready = false
    @init = false
    remaining=undefined
    @julia.stdout.on "data", lis = (data) =>
      data = "" + data
      # console.log data
      data = data.replace(/\033\[\d+m/g, "")
      result = data.split(/\n/g)
      if remaining!=undefined
        result[0] = remaining + result[0]
      remaining = result[result.length-1]
      if result.length>1
        for i in [0...result.length-1]
          tosend = result[i]
          if tosend != undefined
            if detectPrompt(tosend)
              tosend = stripPrompt(tosend)
            answer+=tosend+"\n"
            # @emit "message", tosend
      # console.log data
      if detectPrompt(data)
        @emit "ready"
        @ready = true
        @julia.stdout.removeListener "data", lis
        if @queue.length > 0
          @queue.shift()()
          # @julia.stdin.write @queue.shift()
        # console.log @answer
        # if not @init
          # @emit "ready"
          # @answer = ""
          # @init = true
          # if @queue.length > 0
            # @julia.stdin.write @queue.shift()
#           
        # if @queue.length > 0
          # @julia.stdin.write @queue.shift()
          # @ready = false
        # else
          # @ready = true
        # # else
        # # console.log "ANSWER: ["+@answer+"]"
        # @emit "message", @answer
        # @answer = ""
          # @emit "next"
    @julia.stderr.on "data", (data) =>
      @emit "error", data
    @julia.on "exit", (code) =>
      @emit "exit", code

  execute:(cmd, cb=->)->
    if @ready
      @ready = false
    else
      @queue.push =>
        @execute(cmd,cb)
      return
        
    answer = ""
    remaining=undefined
    @julia.stdout.on "data", lis = (data) =>
      data = "" + data
      # console.log data
      data = data.replace(/\033\[\d+m/g, "")
      result = data.split(/\n/g)
      if remaining!=undefined
        result[0] = remaining + result[0]
      remaining = result[result.length-1]
      if result.length>1
        for i in [0...result.length-1]
          tosend = result[i].trim()
          if tosend and tosend.length > 0
            # console.log tosend
            if detectPrompt(tosend)
              tosend = stripPrompt(tosend)
            else
              tosend = tosend
            answer+=tosend+"\n"
            # @emit "message", tosend
      # console.log data
      if detectPrompt(data)
        # console.log cmd
        answer = answer.replace cmd, ""
        answer = answer.trim /[\n\r]/
        cb(answer)
        @julia.stdout.removeListener "data", lis
        @ready = true
        if @queue.length > 0
          @queue.shift()()
    @julia.stdin.write cmd+'\r'
    # else
      # @queue.push(cmd+'\r')

juliaEval = """
function seval(msg)
  # try to evaluate it
  expr = parse_input_line(msg)

  # evaluate the expression
  try
      # check if the expression was incomplete
    if expr.head == :continue
      return ":continue"
    end
    if expr.head == :error
      return ":error"
    else
      return ":execute"
    end
  catch error
      return ":execute"
  end
  return ":execute"
end
"""

# session = new JuliaSession()
# session.once "ready", ->
  # session.execute "1+2", (result)->
    # console.log "A: "+result
  # session.execute "1+2+3", (result)->
    # console.log "B: "+result
  # session.execute "a = 1+2+3", (result)->
    # console.log "C: "+result
  # session.execute "b = 1+2+3", (result)->
    # console.log "D: "+result
  # session.execute "a + b", (result)->
    # console.log "E: "+result    
  # session.execute "for i = 1:5 println(i) end", (result)->
    # result = result.split '\n'
    # console.log "F: "+result    
# session.once "ready", ->
  # console.log "ready"
  # session.once "message", (msg)->
    # console.log msg
# 
test = new JuliaSession()
test.execute(juliaEval, ->)
# test.once "message", (msg)->
  # console.log msg
# 
# 
# 
# 
# # execute = (cmd)->
# 
# 
# input = "1+2"

uuid = require 'node-uuid'

sessions = {}
sessions[0] = new JuliaSession()

exports.actions = 
  execute:(id, cmd, cb)->
    # console.log cmd
    user_id = @session.user_id
    # cmd = cmd.replace /[\n|\r]/g,"\r"
    # cmd = cmd.replace /\r\r/g,"\r"
    # console.log cmd
    cmds = cmd.split('\n')
    ncmds=[]
    for i in [0...cmds.length]
      toadd = cmds[i].trim()
      if toadd and toadd.length > 0
        ncmds.push toadd
    cmd = ncmds.join '\n'
    # console.log cmd
    test.execute """seval("#{cmd}")""", (data)->
      # console.log data
      if /":execute"/.test(data)
        sessions[id].execute cmd, (data)->
          cb
            success:1
          SS.publish.broadcast 'juliaMessage', 
            cmd:cmd
            result:data
            from:user_id
      else if /^":incomplete"/.test(data)
        cb
          success:0
      else
        cb
          success:0
  restart:(cb)->
    SS.publish.broadcast 'restarting', ""
    sessions[0].julia.kill()
    sessions[0] = new JuliaSession()
    sessions[0].on 'ready', ->
      cb()
      SS.publish.broadcast 'restart', ""
  
  createSession:(cb)->
    id = uuid.v1()
    sessions[id] = new JuliaSession()
    cb id

# cmd = "for i=1:5 \nprintln(i) \nend"
# cmd = cmd.replace /\n|\r/g,""
# exports.actions.execute "0", cmd, (result)->
  # console.log result

