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

import debug
import tables
import os,system,strutils,strscans
import streams
import json
import asyncnet, asyncdispatch
import typetraits
import int_msg_brk
import threadpool
import locks
import queues
import dmesg
import device 
import redis_ext_server
import ./managers/mngr_000
import ./drivers/fake/fake_driver
#import ./drivers/own/own_driver

# JSON Objects
type Manager = object
  id:string
  group:string
  typem:string
  algo:seq[string]

type ComService = object 
  id:string
  ip:string
  port:int
  extip:string
  extport:int

type HostConfig = object
  hostID:string
  location:string
  intmsgbrkport:int
  comservices:seq[ComService]
  drivers:seq[string]
  managers:seq[Manager]
  devices:seq[Device]

var config:HostConfig # global config var


# SYSTEM OBJECTS
type CommService = object
type EKeyboardInterrupt = object of Exception

# INTERNAL MSG BROKER DMSG TABLE
var glock: Lock
var msgq{.guard: glock.} = newSeq[Dmessage]()

# INTERNAL MANAGED DEVICE TABLE
var mdev = newSeq[Device]()

# PROCS
proc `$`*[T](some:typedesc[T]): string = name(T)

proc handler() {.noconv.} =
  raise newException(EKeyboardInterrupt, "Keyboard Interrupt")

proc load_file_config(file_prefix_path:string, json_object: typedesc)=
  let config_file_suffix= "_config.json"
   # read host config file
  try:
    let s = newFileStream(getAppDir() & file_prefix_path & config_file_suffix)
    var json_text = s.readAll()
    config = to(parseJson(json_text), json_object)
    s.close()
  except IOError:
    echo "File not found - ABORT"

# -- MAIN
when isMainModule:
  
  # -- hook for ctrl-c
  setControlCHook(handler)

  # -- create host, load config file
  load_file_config("/configs/host", HostConfig)
  log( "-> Creating Host: " & config.hostID )

  # -- load devices 
  if config.devices.len > 0:
      for dev_item in 0..<config.devices.len:
        let cdev:Device = config.devices[dev_item]
        mdev.add(cdev)

  # -- load, config and run external comm services -- asynch
  if config.comservices.len > 0:
    var comm_serv:string
    var comm_serv_num:int
    for comsrvcitem in 0..<config.comservices.len:
      let cser:ComService = config.comservices[comsrvcitem]
      let cser_id:string = cser.id
      if scanf(cser_id,"$*.$i",comm_serv,comm_serv_num):
        case comm_serv:
        of "mqtt":
          log("->> got mqtt"& $comm_serv_num )
        of "api":
          log("->> got api"& $comm_serv_num)
        of "nanomsg":
          log("->> got nanosmg"& $comm_serv_num)
        of "redis":
          log("->> got redis"& $comm_serv_num)
          asyncCheck ext_redis_server(addr(msgq),
                                      cser.ip,
                                      cser.port,
                                      cser.extip,
                                      cser.extport)
        else:
          log("-> fail to load commservice")
          quit()

  # -- load, config and run internal message broker -- asynch
  log("->> start internal message broker")
  asyncCheck int_msg_brk(addr(msgq),
                         addr(mdev),
                         "127.0.0.1",
                         config.intmsgbrkport)

  # -- load, config and run drivers -- threads
  if config.drivers.len > 0:
    var drv_serv:string
    var drv_serv_num:int
    for drv_item in 0..<config.drivers.len:
      let cdrv:string = config.drivers[drv_item]
      if scanf(cdrv,"$*.$i",drv_serv,drv_serv_num):
        case drv_serv:
        of "own":
          log("->> todo own drv" & $drv_serv_num)
        of "fake":
          log("->> spawn fake drv thread" & $drv_serv_num)
          spawn fake_drv(addr(msgq), drv_serv_num)
        else:
          log("->> fail to load drv")
          quit()

  # --  load, config and run managers -- asynch
  if config.managers.len > 0:
    for mngr_item in 0..<config.managers.len:
      let cmngr:Manager = config.managers[mngr_item]
      let cmngr_id:string = cmngr.id
      var mngr_serv:string
      var mngr_serv_num:int
      if scanf(cmngr_id,"$*.$i",mngr_serv,mngr_serv_num):
        spawn manager_init(mngr_serv_num,
                           cmngr.group,
                           cmngr.typem,
                           cmngr.algo,
                           addr(msgq))


  # -- main loop
  try:
    log("->> main run loop")
    runForever()
  except EKeyboardInterrupt:
    echo "\n---> END <---"
