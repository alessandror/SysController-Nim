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

import asyncnet, asyncdispatch
import queues
import marshal
import dmesg
import device
import locks

const ack  = "{\"int_msg_brk\":\"ok\"}" #ack 
const nack = "{\"int_msg_brk\":\"fail\"}" #nack
var clients {.threadvar.}: seq[AsyncSocket]
var glock: Lock

proc send_nack(client: AsyncSocket){.async.}=
   echo "--> send nack" 
   await client.send(nack & "\r\L")

proc processClient(client: AsyncSocket, 
                   mqueue: ptr seq[Dmessage],
                   mdev: ptr seq[Device]) {.async.} =
  var msgrcvd:string = ""
  echo "--> processing dmsgs"
  {.locks: [glock].}:
    for i, c in clients:
      msgrcvd = await c.recvLine()
      echo "<-- dmsg rcvd " & $msgrcvd

      # -- check incoming message structure by marshalling 
      let msg_to_process = to[Dmessage](msgrcvd)

      # -- check if the message is valid in fclass
      # -- check on string lenght
      if len(msg_to_process.src) > 255:
        discard send_nack(c)
      elif len(msg_to_process.dst) > 255:
        discard send_nack(c)
      elif len(msg_to_process.msgtype) > 255:
        discard send_nack(c)
      elif len(msg_to_process.fclass) > 255:
        discard send_nack(c)
      elif len(msg_to_process.cmd) > 100:
        discard send_nack(c)
      elif len(msg_to_process.params) > 10: 
        discard send_nack(c)
      else:    
        for i in mdev[]:
          # -- check the dmessage.src on msg id 
          if msg_to_process.dst == i.id:
            # -- insert message in queue
            mqueue[].add(msg_to_process)
          else:
            # -- reply to client
            echo "--> send nack" 
            await c.send(nack & "\r\L")

      c.close()
      clients.delete(i)

proc int_msg_brk*(mqueue: ptr seq[Dmessage],
                  mdev: ptr seq[Device],
                  server_address:string, 
                  server_port:int) {.async.} =
  clients = @[]
  var server = newAsyncSocket()
  server.bindAddr(Port(server_port),server_address)
  server.listen()

  while true:
      let client = await server.accept()
      clients.add client
      asyncCheck processClient(client,mqueue,mdev)

