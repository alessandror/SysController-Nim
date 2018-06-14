#[
Copyright 2018 Alex Redaelli <a.redaelli at gmail dot com>

Permission is hereby granted, free of charge, to any person obtaining a copy of this
software and associated documentation files (the "Software"), to deal in the Software
without restriction, including without limitation the rights to use, copy, modify, 
merge, publish, distribute, sublicense, and/or sell copies of the Software, and to 
permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or
substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A 
PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT 
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR 
THE USE OR OTHER DEALINGS IN THE SOFTWARE.
]#

import strutils,strscans
import net

const own_server_address ="127.0.0.1"
var cmds = newSeq[string]()
var th0:Thread[seq[string]]

let valid_c={'0'..'9','*','#'}
let invalid = AllChars - valid_c  
const match_status_req = "*#$i*$i##" # status req *#CHI*DOVE##
const match_value_req = "*#$i*$i*$i##" # value req *#CHI*DOVE*GRANDEZZA##
const match_status_rsp = "*#*$i##" #ack ==1/nack ==0
const select_command_session = "*99*0##"
const select_event_session = "*99*1##"
var t0,t1,t2,t3:int

#RSPS
proc own_check_msg (msg:string): bool = 
  if msg.find(invalid) == -1:
    true
  else:
    false

proc own_parse_msg(msg:string):int =
  if own_check_msg(msg):
    if scanf(msg,match_status_rsp,t0):
      echo "status msg"
      echo $t0
      result = t0 #0=nack/1=ack 
 
    if scanf(msg,match_status_req,t0,t1):
      echo "status req"
      echo $t0
      echo $t1
      result =  2
  
    if scanf(msg,match_value_req,t0,t1,t2):
      echo "value match"
      echo $t0
      echo $t1
      echo $t2
      result =  3
  else:
    result = -1

#CMDS
proc own_cmd(who:int, what:int, what_args: varargs[int], where:int, where_args: varargs[int]):string = 
  var wp,wa,msg:string
  for i in items(what_args):
    wp = wp & "#" & $i 
  for i in items(where_args):
    wa = wa & "#" & $i 
  msg = "*" & $who & "*" & $what & wp & "*" & $where & wa & "##"

proc own_status_req(who:int, where:int):string = # must be in command mode
  var msg = "*#" & $who & "*" & $where & "##"

proc own_val_req(who:int, where:int, value:int, value_args: varargs[int]):string = # must be in command mode
  var va,msg:string
  for i in items(value_args):
    va = va & "*" & $i
  msg = "*#" & $who & "*" & $where & "*" & $value & va & "##"

proc own_rcv_msg (client:Socket):string =
  var msgrcv = ""
  var numbytercvd:int
  echo "->rcv message"
  try:
    while true:
      msgrcv = msgrcv & recv(client,1,500)
      #echo "->msg rcv " & msgrcv
  except TimeoutError:
    discard 
  return msgrcv[0..len(msgrcv)-1]

#OWN SESSION 
proc own_session(cmds:seq[string]) {.thread.} =
  echo "->in own_session"
  var msgrcv:string
  var rsp_type:int
  var client = newSocket()
  
  #0: authentication todo
  
  #1: session connect and rcv ack
  echo "->connect to server and rcv msg"
  echo "->socket connect"
  client.connect(own_server_address, Port(20000))
      
  msgrcv = own_rcv_msg(client)
  echo "->msgrcv " & msgrcv
  echo "->len " & $len(msgrcv)

  rsp_type = own_parse_msg(msgrcv)
  if rsp_type > 0:    #match if valid OWN message
    if rsp_type == 1: #match status resp
      echo "<- ACK RECEIVED 0"
      client.send(select_command_session)
      rsp_type = own_parse_msg(msgrcv)
      if rsp_type > 0:
        if rsp_type == 1: #match status resp
          echo "<- ACK RECEIVED 1"
          client.send(select_command_session)
        else:
          echo "->no response from server" 
          return  
      else:
        echo "->not valid own msg"
    else:
      echo "->no response from server" 
      return
  else:
    echo "->not valid own msg" 
  
  # process set of commands 
  # for m in cmds: #send msg first command is session type
  #   if not trySend(client,m):
  #     echo("own comm error") #todo gestire errore e retry
  #   msgrcv = recv(client,1)
  #   while msgrcv != "":
  #     msgrcv = msgrcv & recv(client,1)
  #     if own_parse_msg(msgrcv) > 0:
  #       discard
  #     else:
  #       echo "not valid own msg" 
  
  client.close()
 

when isMainModule:
  echo "->create own client thread"
  createThread(th0, own_session, @[])
  echo "->join own client thread"
  joinThread(th0)
