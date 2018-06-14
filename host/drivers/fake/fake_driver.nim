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

import os
import queues
import json
import marshal
import ../../dmesg

type logic_states {.pure.} = enum
  init, listen, process, flush_message

var v:int = 0
var cstate:int = int(logic_states.init)

proc logic(v:int, mqueue: ptr seq) =
  {.locks: [glock].}: # lock on object
    var processed_mesg:int = 0
    case logic_states(v):
    of logic_states.init:
      echo "--> fake_drv init"
    of logic_states.listen:
      echo "--> fake_drv listen"
      # -- check messages in the queue
      if mqueue[].len > 0:
        for processed_mesg in 0..<len(mqueue[]):
          echo "--> queue msg: " & $mqueue[processed_mesg]
          let msg1 = $$mqueue[processed_mesg] #marshal of data, check if object is valid
          #echo $$msg.dst
          if "fake_drv" in $$mqueue[processed_mesg].dst: 
            echo "--> find fake driver message in queue"
            # -- process logic
            cstate = int(logic_states.process)
    of logic_states.process:
      echo "--> fake_drv process logic"
      cstate = int(logic_states.flush_message)
    of logic_states.flush_message:
      echo "--> fake_drv flush_message"
      mqueue[].delete(processed_mesg)
      cstate = int(logic_states.listen)

proc fake_drv*(mqueue: ptr seq, drv_num:int) {.thread.} =
  echo "--> init fake_drv " & $drv_num
  # -- 1 config driver
  cstate = int(logic_states.init)
  logic(cstate,mqueue)
  # -- 2 process driver logic
  cstate = int(logic_states.listen)
  # -- 3 process state machine
  while true:
    logic(cstate,mqueue)
    sleep(1000)
