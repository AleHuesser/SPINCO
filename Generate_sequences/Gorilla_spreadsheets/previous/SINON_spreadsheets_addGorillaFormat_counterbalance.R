dirinput <- 'V:/spinco_data/SINON/Spreadsheets/LexicalDecision/'
basefilename <- 'TrialSequences_LD_Gorilla'
setwd(dirinput)



dat <- openxlsx::read.xlsx(paste0(basefilename,'.xlsx'))


uridx1 <- which(dat$block=='block1')
uridx2 <- which(dat$block=='block2')
uridx3 <- which(dat$block=='block3')
uridx4 <- which(dat$block=='block4')


newdat <- dat
newdat[uridx1,] <- dat[uridx1,]
newdat[uridx2,] <- dat[uridx2,]
newdat[uridx3,] <- dat[uridx3,]
newdat[uridx4,] <- dat[uridx4,]

openxlsx::write.xlsx(paste0(basefilename,'_cb1234.xlsx'),x = newdat)

newdat <- dat
newdat[uridx1,] <- dat[uridx3,]
newdat[uridx2,] <- dat[uridx2,]
newdat[uridx3,] <- dat[uridx1,]
newdat[uridx4,] <- dat[uridx4,]

openxlsx::write.xlsx(paste0(basefilename,'_cb3214.xlsx'),x = newdat)

newdat <- dat
newdat[uridx1,] <- dat[uridx1,]
newdat[uridx2,] <- dat[uridx4,]
newdat[uridx3,] <- dat[uridx3,]
newdat[uridx4,] <- dat[uridx2,]

openxlsx::write.xlsx(paste0(basefilename,'_cb1432.xlsx'),x = newdat)

newdat <- dat
newdat[uridx1,] <- dat[uridx3,]
newdat[uridx2,] <- dat[uridx4,]
newdat[uridx3,] <- dat[uridx1,]
newdat[uridx4,] <- dat[uridx2,]
openxlsx::write.xlsx(paste0(basefilename,'_cb3412.xlsx'),x = newdat)


newdat <- dat
newdat[uridx1,] <- dat[uridx2,]
newdat[uridx2,] <- dat[uridx1,]
newdat[uridx3,] <- dat[uridx4,]
newdat[uridx4,] <- dat[uridx3,]
openxlsx::write.xlsx(paste0(basefilename,'_cb2143.xlsx'),x = newdat)


newdat <- dat
newdat[uridx1,] <- dat[uridx4,]
newdat[uridx2,] <- dat[uridx1,]
newdat[uridx3,] <- dat[uridx2,]
newdat[uridx4,] <- dat[uridx3,]
openxlsx::write.xlsx(paste0(basefilename,'_cb4123.xlsx'),x = newdat)


newdat <- dat
newdat[uridx1,] <- dat[uridx2,]
newdat[uridx2,] <- dat[uridx3,]
newdat[uridx3,] <- dat[uridx4,]
newdat[uridx4,] <- dat[uridx1,]
openxlsx::write.xlsx(paste0(basefilename,'_cb2341.xlsx'),x = newdat)


newdat <- dat
newdat[uridx1,] <- dat[uridx4,]
newdat[uridx2,] <- dat[uridx3,]
newdat[uridx3,] <- dat[uridx2,]
newdat[uridx4,] <- dat[uridx1,]
openxlsx::write.xlsx(paste0(basefilename,'_cb4321.xlsx'),x = newdat)





