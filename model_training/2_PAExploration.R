# Not complete
load(file.path(datadir,'absence.RData'))
load(file.path(datadir,'presence.RData'))
PA <- rbind(mydata.eurobis,absence)
save(PA,file=file.path(datadir,"PA.RData"))


