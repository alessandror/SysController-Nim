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
import redis 

var clients {.threadvar.}: seq[AsyncSocket]
const ack = "OK" #ack 
const nack = "KO" #nack
var server_port:int 
var server_address:string
var r {.threadvar.} : Redis

proc set_port*(port:int)=
  server_port=port

proc set_address*(address:string)=
  server_address=address

proc processClient(client: AsyncSocket) {.async.} =
  var msgrcvd = ""
  # echo "->processing client"
  # #for i, c in clients:
  # echo "->send ack" 
  # await client.send(ack)

  msgrcvd = await client.recvLine()
  echo "<- msg rcvd " & $msgrcvd
  r.setk("test_ext_server","test")

  #processlogic commands
  #todo

  #clients.delete(i)

proc ext_redis_server*(mqueue: ptr seq,
                       server_address:string, 
                       server_port:int,
                       extip:string,
                       extport:int) {.async.} =
  
  # -- connect to redis
  r = redis.open(host=extip, port=extport.Port)
  
  clients = @[]
  var server = newAsyncSocket()
  server.bindAddr(Port(server_port),server_address)
  server.listen()

  while true:
      let client = await server.accept()
      clients.add client
      asyncCheck processClient(client)











