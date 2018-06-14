#!/usr/bin/gdb -P
import sys
import gdb

def on_stop(p):
  (status, value) = p.status
  if status != gdb.EXIT:
    gdb.cli ()
  else:
    sys.exit (value)

gdb.execute("b host.nim:71")
gdb.execute("r")

print(gdb.inferiors())

if len(gdb.inferiors()) > 0:
    c_process = gdb.selected_inferior()

    print(c_process)
    print(c_process.threads())
    print(c_process.pid)
    print(c_process.num)

