@if not exist C:\Windows\Patchlog md c:\Windows\Patchlog
@echo Force domain group policy update now.>C:\Windows\Patchlog\force_gp_update.log
@echo N | gpupdate /force /wait:60 >>C:\Windows\Patchlog\force_gp_update.log
