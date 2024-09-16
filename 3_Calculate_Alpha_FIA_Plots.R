library(rstan)
library(rstantools)
library(posterior)
library(data.table)
library(doParallel)
library(parallelly)
library(future)
library(dplyr)
library(tidyr)

sizeabundance3<-fread("sizeabundanceallplots.csv")%>%
  data.frame()

select<-dplyr::select
model <- stan_model(file = "density1_simplified.stan")
cores<-detectCores()
cl <- makePSOCKcluster(cores)
registerDoParallel(cl)

foreach(i = unique(sizeabundance3$plot_ID))%dopar%{
  library(rstan)
  library(rstantools)
  library(posterior)
  library(data.table)
  library(doParallel)
  library(parallelly)
  library(future)
  library(dplyr)
  library(tidyr)
  test<-sizeabundance3%>%
    filter(plot_ID == i)%>%
    drop_na(DIA)
  if(nrow(test)<25){
    print("problem")
  }else{
    
    N<-length(test$DIA)
    x<-test$DIA
    x_min<-5
    x_max<-max(test$DIA)
    
    stan_dat<-list(N=N,x=x,x_min=x_min,x_max=x_max)
    # startTime <- Sys.time() 
    fit <- sampling(model, data = stan_dat, 
                    iter=9000, warmup=6000, chains = 4,cores=4)
    
    
    data<-summarize_draws(fit)
    data$N_Trees = nrow(test)
    data<-data%>%
      mutate(plot_ID = unique(test$plot_ID))%>%
      mutate(INVYR = unique(test$INVYR))%>%
    fwrite(data,
           file=paste0("foldertokeepfilesin/",
                       i,".csv"))
  }
  
}