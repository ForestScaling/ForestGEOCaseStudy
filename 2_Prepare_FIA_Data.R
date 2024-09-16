library(tidyverse)  # Load the tidyverse package, which includes various data manipulation and visualization tools
library(data.table) # Load the data.table package for efficient data manipulation

# # Define a vector of the lower 48 states
successfulstates <- c("AL", "AZ", "AR", "CA", "CO", "CT", "DE", "FL", "GA", "ID", "IL", "IN", "IA", "KS", "KY", "LA", "ME", "MD", "MA", "MI", "MN", "MS", "MO", "MT", "NE", "NV", "NH", "NJ", "NM", "NY", "NC", "ND", "OH", "OK", "OR", "PA", "RI", "SC", "SD", "TN", "TX", "UT", "VT", "VA", "WA", "WV", "WI", "WY")

# Create a regular expression pattern to match filenames to get the data frame with the data for plot conditions
pattern <- paste0("(", paste(successfulstates, collapse = "|"), ")_COND\\.csv$")

# Find filenames matching the pattern in the specified directory
filenames <- list.files("R:\\Adam Eichenwald\\FIA\\", pattern = pattern, full.names = TRUE)
rename<-dplyr::rename
select<-dplyr::select
filter<-dplyr::filter
# Read each CSV file into a data.table and combine them into a single data.frame. Then we need to filter to just those plots where the stand is natural and not established by artificial seeding and planting (STDORGCD == 0, natural pots)
condition <- lapply(filenames, fread) %>%
  rbindlist() %>%
  data.frame() %>%
  filter(STDORGCD == 0)

summarize<-dplyr::summarize
condition<-condition%>%
  mutate(pltID = paste(STATECD, UNITCD,COUNTYCD,PLOT, sep = "_"))%>%
  group_by(pltID, INVYR)%>%
  drop_na(STDAGE)%>%
  summarize(STDAGE = weighted.mean(STDAGE, w = CONDPROP_UNADJ, na.rm = TRUE))%>%
  ungroup()

# Create a new regular expression pattern to match filenames for plot data
pattern <- paste0("(", paste(successfulstates, collapse = "|"), ")_PLOT\\.csv$")

# Find filenames matching the new pattern in the specified directory
filenames <- list.files("R:\\Adam Eichenwald\\FIA\\", pattern = pattern, full.names = TRUE)

# Filter out filenames containing "OZONE", since pattern has "plot_ozone" and "plot", and we don't want plot_ozone
filenames <- filenames[!grepl("OZONE", filenames)]

# Read each CSV file into a data.table and combine them into a single data.frame. Then we don't want periodic inventory plots (KINDCD == 0) or modeled periodic inventory plots (KINDCD == 4). The rest are normal plots
plot <- lapply(filenames, fread) %>%
  rbindlist(fill = TRUE) %>%
  data.frame() %>%
  filter(KINDCD != 0 & KINDCD != 4)

# Join plot data with condition data based on common columns INVYR, STATECD, UNITCD, COUNTYCD, PLOT, and PLT_CN
plotcond <- inner_join(plot %>% 
                         mutate(pltID = paste(STATECD, UNITCD,COUNTYCD,PLOT, sep = "_"))%>%
                         dplyr::rename(PLT_CN = CN), condition,
                       by = c("INVYR", "pltID"))

# Find filenames matching a new pattern for the TREE data tables, which have all the individual tree information.
filenames <- list.files("R:\\Adam Eichenwald\\FIA\\", pattern = "_TREE.csv", full.names = TRUE)

# Filter filenames based on desired states
filtered_filenames <- filenames[grep(paste0("\\", paste(successfulstates, collapse = "|"), "_"), filenames)]

# Read each CSV file into a data.table and combine them into a single data.frame
treetable <- filtered_filenames %>%
  lapply(fread) %>%
  rbindlist()%>%
  data.frame()
treetable<-treetable%>%
  dplyr::select(INVYR, CN,PREV_TRE_CN,PLT_CN,STATUSCD,ACTUALHT,
                STATECD,UNITCD,COUNTYCD,PLOT,SUBP,SPCD, DIA, SPGRPCD,TPA_UNADJ)%>%
  mutate(CN=as.numeric(CN))%>%
  #comment out to calculate mortality
  filter(STATUSCD == 1)
select<-dplyr::select
filter<-dplyr::filter
# Select relevant columns from plotcond and treetable, then join them based on common columns INVYR and PLT_CN.
sizeabundance <- plotcond %>%
  select(INVYR, STATECD, UNITCD, COUNTYCD, PLOT, STDAGE, PLT_CN, KINDCD, DESIGNCD, LON, LAT) %>%
  inner_join(treetable %>% 
               data.frame() %>% 
               filter(STATUSCD == 1)%>%
               mutate(pltID = paste(STATECD, UNITCD,COUNTYCD,PLOT, sep = "_"))%>%
               select(INVYR, STATECD,UNITCD,COUNTYCD,PLOT,SUBP,SPCD, DIA,pltID,
                      STATUSCD,SPGRPCD, ACTUALHT,PLT_CN), 
             by = c("INVYR","STATECD", "UNITCD","COUNTYCD","PLOT"))# %>%


sizeabundance%>%
  mutate(pltID = paste(STATECD, UNITCD, COUNTYCD, PLOT, sep = "_"))%>%
  filter(DIA>5 & # under 5 inches is a different kind of plot measurement for FIA
           DIA < 19.68504 #approx 50 cm
         )%>%
  filter(INVYR>=2001)%>%#measurement strategies were different after 2001, so we make sure we only use that data
  group_by(pltID)%>%
  filter(INVYR == max(INVYR) #use most recent plot data
         )%>%
  fwrite("sizeabundanceallplots.csv")
rm(treetable)
gc()