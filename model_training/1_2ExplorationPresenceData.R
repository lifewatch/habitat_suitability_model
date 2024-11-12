
# data is mydata_eurobis
#spatial data is spatial_extent




# monthly plots -----------------------------------------------------------

#Spatial plot
ggplot(data=spatial_extent)+
  geom_sf()+
  theme_minimal()+
  geom_point(data=mydata_eurobis, aes(x=longitude,y=latitude,colour="red"),show.legend=FALSE) +
  theme(plot.title = element_text(size=14), axis.title= element_text(size = 12),
        text = element_text(size = 12))+
  labs(title = paste("eurOBIS occurrence records Harbour porpoise"))+
  coord_sf(xlim = c(bbox[1],bbox[3]), ylim = c(bbox[2], bbox[4]), expand=FALSE)+
  facet_wrap(~month, nrow= 4)+
  theme_void()+
  theme(strip.background=element_blank(), #remove strip background
        strip.text= element_text(size=12))

#Bar plot
ggplot(data = mydata_eurobis, aes(x = as.factor(month))) + 
  stat_count()+
  theme(plot.title = element_text(size=14), axis.title= element_text(size = 12),
        text = element_text(size = 12))+
  labs(title = paste("eurOBIS occurrence records Harbour porpoise"))

# decadal plots -----------------------------------------------------------

#Spatial plot
ggplot(data=spatial_extent)+
  geom_sf()+
  theme_minimal()+
  geom_point(data=mydata_eurobis, aes(x=longitude,y=latitude,colour="red"),show.legend=FALSE) +
  theme(plot.title = element_text(size=14), axis.title= element_text(size = 12),
        text = element_text(size = 12))+
  labs(title = paste("eurOBIS occurrence records Harbour porpoise"))+
  coord_sf(xlim = c(bbox[1],bbox[3]), ylim = c(bbox[2], bbox[4]), expand=FALSE)+
  facet_wrap(~decade, nrow= 2)+
  theme_void()+
  theme(strip.background=element_blank(), #remove strip background
        strip.text= element_text(size=12))
  
#Bar plot
ggplot(data = mydata_eurobis, aes(x = decade)) + 
  stat_count()+
  theme(plot.title = element_text(size=14), axis.title= element_text(size = 12),
        text = element_text(size = 12))+
  labs(title = paste("eurOBIS occurrence records Harbour porpoise"))
  
  
















# Get the name and the y position of each label
label_data <- data
number_of_bar <- nrow(label_data)
angle <- 90 - 360 * (label_data$group_id-0.5) /number_of_bar     # I substract 0.5 because the letter must have the angle of the center of the bars. Not extreme right(1) or extreme left (0)
label_data$hjust <- ifelse( angle < -90, 1, 0)
label_data$angle <- ifelse(angle < -90, angle+180, angle)

# Make the plot
ggplot(data, aes(x=as.factor(group_id),y=log(count),fill=year)) +       # Note that id is a factor. If x is numeric, there is some space between the first bar
  geom_bar(stat='identity',alpha=0.5) +
  theme_minimal() +
  theme(
    legend.position = "none",
    axis.text = element_blank(),
    axis.title = element_blank(),
    panel.grid = element_blank(),
    plot.margin = unit(rep(-1,4), "cm") 
  ) +
  coord_polar()+
  geom_text(data=label_data, aes(x=group_id, y= log(count)+0.5, label=month, hjust=hjust), color="black", fontface="bold",alpha=0.6, size=2.5, angle= label_data$angle) 

```
```{r, fig.width=8, fig.height=12}
#Create data
puntdata <- mydata.eurobis%>%
  mutate(year=ordered(year),month=ordered(month,labels=month.abb))%>%
  dplyr::select(-day)%>%
  group_by(year,month)%>%
  na.omit()%>%
  mutate(group_id = cur_group_id())

#to re-order so the rows are different seasons
new_order <- c(month.abb[12],month.abb[1:11])

for (jaar in levels(puntdata$year)){
  plotdata <- puntdata %>%
    filter(year==jaar)%>%
    mutate(month=factor(month,levels=new_order))
  
  plot<-ggplot(data=world) +
    geom_sf()+
    theme_minimal()+
    geom_point(data=plotdata, aes(x=x,y=y,colour="red"),show.legend=FALSE) +
    theme(plot.title = element_text(size=20), axis.title= element_text(size = 16),
          text = element_text(size = 16))+
    labs(title = paste("OBIS occurrence records Harbour porpoise",jaar))+
    coord_sf(xlim = c(-30,60), ylim = c(30, 85), expand=FALSE)+
    facet_wrap(~month, nrow= 4)+
    theme_void()+
    theme(strip.background=element_blank(), #remove strip background
          strip.text= element_text(size=12))
  print(plot)
}





#Remove months for which we have less than 20 observations
months_filtered <- mydata_eurobis%>%
  group_by(year_month)%>%
  summarize(count=n())%>%
  filter(count>=20)
mydata_eurobis <- mydata_eurobis%>%filter(year_month %in% months_filtered$year_month)

