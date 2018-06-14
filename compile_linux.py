from subprocess import Popen, PIPE

COMMAND ="nim c --opt:none --debugger:native --debuginfo --linedir:on --threads:on ./host/host.nim"


p = Popen(COMMAND.split(), stdout=PIPE, stderr=PIPE)

out,err= p.communicate()

print(out)
print(err)
