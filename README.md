# SysController-Nim
Research project for learning Nim language and testing it on a real case scenario.

Base framework for managing subsystems(sensors, actuators, ..) by drivers and command logic (FClass) sending messages DMESG. You can set up running logic by extending  managers.

The framework supports OWN (open web net ) drivers and a fake driver for testing.

The code use both threaded ad asynch programming.

* compile host.nim from root dir[nim 0.18.x] with:
    * mac osx: nim --opt:none --debugger:native --debuginfo --linedir:on --threads:on c ./host/host.nim
    * linux: nim --opt:none --debugger:native --debuginfo --linedir:on --threads:on  ./host/host.nim
    * run redis-server
    * run host
* to test host run:
    * compile testcode/test_sock_client.nim


##  SYSTEM


```
                    +---------------------+                                           
                    |       DMESG         |                                           
                    +----/------------\---+                                           
                      /--              -\                                             
                   /--                   --\                                          
                /--                         -\                                        
   +---------------------+          +---------------------+                           
   |   int msg broker    |          |   ext comm server   |                           
   +----------\----------+          +----------/----------+                           
               -\                             |                                       
                 \                            / -                                     
   +-----------------------------------------|------------+                           
   |                   message queue                      |                           
   +--------------/----------------------------\----------+                           
                 /                           \  -------\                              
                /                             |         ------\                       
               /                              \                -------\               
   +---------------------+          +----------|----------+    +---------------------+
   |       driver        |          |       driver        |    |       manager       |
   +---------------------+          +---------------------+    +---------------------+

 ```


### DMESG  MESSAGE FORMAT

```
{ "id":<string>,
  "time:<string>,
  "src":<string>,
  "dst:"<string>,
  "msgtype":<string>,
  "fclass":<string>,
  "cmd":<string>,
  "params":[<string>],
  "auth":<string>
}
```
#### DMESG Fields

>msgtype
```
synexe
asynexe
signal
response
```

>cmd:
```
get_all_devices
get_device
get_all_managers
set 
get
```

## FCLASS(function classes)  LIST
* SwitchON
* SwitchOFF

## HOST CONFIG example (see /configs dir)

host configuation file.

 ```
{
    "hostID": "host-000",
    "location": "MRD_GW0",
    "intmsgbrkport": 12345,
    "comservices": ["mqtt.000", "api.000"],
    "drivers": ["own.000", "fake.000"],
    "managers": [{
        "id": "mngr.000",
        "group": "home",
        "typem": "local_manager",
        "algo": ["energy_manager.000", "security_manager.000"]
    }],
    "devices": [{
        "id": "light.000",
        "group": "home",
        "location": "",
        "fclass": "BinaryLight",
        "driver": "own.000",
        "commands": ["ON.00", "OFF.000"]
    }]
}
 ```