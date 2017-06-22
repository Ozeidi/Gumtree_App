# ###############################################
#Application Names: Gumtree App
#         Author:Omar Al Zeidi
#         Last Modification Date: 10th June 2017 
# Description: This code is intended to help users looking for cars on gumtree.
#The code demonstrates basic implementation of shiny,
#ggplot and leaflet for interactive visualization application.
# Library Dependencies: RColorBrewer, shiny, ggplot2, leaflet, ggmap, rstudioapi,scales
####################################
library(shiny)
library(ggplot2)
library(leaflet)
# needed for color palette
library(RColorBrewer)
# needed for directory mapping
#library(rstudioapi)
#needed for proper number formating on plots
library(scales)
#####################################


#setting working directory to the source folder
#setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
df<-read.csv('Dataset/DatasetV2.0_Cleansed.txt',sep = '\t')
#Convert km variable to numeric
df$Km=as.numeric(df$Km)
#extract the mongth out of DateListed
df$DateListed<-gsub(' ','',df$DateListed)
df$DateListed<- as.numeric(substr(df$DateListed,4,5))
#convert DateListed to factor
df$DateListed<-factor(df$DateListed)
levels(df$DateListed)<-c('JAN','FEB','MAR','APR','MAY','JUN','JUL','AUG','SEP','OCT','NOV','DEC')

#Function to create price clusters
priceClassifier<-function(x){
  x<-as.numeric(x)
  if (x<10000){resutl<- '<10K'}
  else if (x>=10000 & x <20000){result <- '10K-20K'}
  else if (x>=20000 & x <50000){result<- '20K-50K'}
  else if (x>=50000 & x <100000){result<- '50K-100K'}
  else if (x>=100000) {result<- '>100K'}
}
df$PriceCluster<-mapply(priceClassifier,df$Price)
levels(df$PriceCluster) <-   c('<10K','10K-20K','20K-50K', '50K-100K','>100K')
df$PriceCluster<-factor(df$PriceCluster,levels = levels(df$PriceCluster))

Makers_Models <- unique(df[c('Make','Model')])
Makers<- unique(Makers_Models[,1])

#Define color pallete for price clusters
PriceColors <- brewer.pal(5,"Set1")
names(PriceColors) <- levels(df$PriceCluster)
PriceScale <- scale_colour_manual(name = "PriceCluster",values = PriceColors)
pal<- colorFactor(PriceColors,domain =levels(df$PriceColors) )


#########################################################
######################Shiny App##########################
#########################################################

ui<-navbarPage("Interactive App", id="nav",
               
               
               tabPanel("Gumtree Watcher",
                        div(class="outer",
                            tags$head(
                              # Include custom CSS inspired by :https://shiny.rstudio.com/gallery/superzip-example.html
                              includeCSS("www/styles.css")
                            ),
                            #Main window of leaflet map
                            leafletOutput("plotmap", width="100%", height="100%"),
                            #Left-side filter pane
                            absolutePanel(id = "controls", class = "panel panel-default", fixed = TRUE,
                                          draggable = FALSE, top = 60, left =20 , right = "auto", bottom = "auto",
                                          width = 330, height = "auto",
                                          
                                          h2("Australia Car Watcher"),
                                          checkboxInput(inputId = 'inCluster',label = "Enable proximity clustering",value=TRUE),
                                          selectInput(inputId = 'inMake',label = 'Car maker:',choices = c('All',as.character(sort(Makers))), selected = 'All'),
                                          conditionalPanel("input.inMake != 'All'",
                                                           selectInput(inputId = 'inModel',label = 'Car Model:',choices = "")),
                                          sliderInput(inputId = 'inYear',label="Manufacturing Year",min=1900,max=2017,value=c(1900,2017)),
                                          sliderInput(inputId = 'inPrice',label="Price Range in K$",min=0,max=1000,value=c(0,1000))
                            ),
                            #Right-side plots pane
                            absolutePanel(id = "Plots",h2(HTML('<p style="text-align: center;">Cars Statistics</p>')), class = "panel panel-default", fixed = TRUE,
                                          draggable = FALSE, top = 60, left = "auto", right = 20, bottom = "auto",
                                          width = 400, height = "auto",
                                          plotOutput(outputId = 'plotPrice',height =300,
                                                     click = 'plotPrice_click',
                                                     brush=brushOpts(id='plotPrice_brush')),
                                          plotOutput(outputId = 'histMonth',height = 200)
                                          ,radioButtons("in_agg_sel","Select aggregation method", c("Car Counts" = "CNT", "Price Average" = "AVG") , inline=T)
                                          
                            ),
                            
                            tags$div(id="cite"," This data has been collected in March 2017")
                        )
               ),
               
               tabPanel("Explorer",
                        fluidRow(
                          column(12,
                                 dataTableOutput('mytable')
                          )
               )
               )
)




# Define server procedures for visulaisation
server<-function(input, output,session) {
  showModal(modalDialog(
    title = "Introduction",
    includeHTML('www/Intro.htm'),
    width = 370, height = "auto",
    easyClose = TRUE
  ))
  #draw leaflet map based on lat-lon bounds in the data
  output$plotmap <- renderLeaflet({
    leaflet(data = df) %>% addTiles(group = "OSM (default)") %>%
      addProviderTiles(providers$Stamen.Toner, group = "Toner") %>%
      addProviderTiles(providers$Stamen.TonerLite, group = "Toner Lite") %>%
      # add option to select map layout
      addLayersControl(
        baseGroups = c("OSM (default)", "Toner", "Toner Lite"),
        options = layersControlOptions(collapsed = TRUE)
      ) %>%
      fitBounds(~min(Lng), ~min(Lat), ~max(Lng), ~max(Lat))
  })  
  #function Filter the data based on user selection
  df_slice<-reactive({
    bounds <- input$plotmap_bounds
    latRng <- range(bounds$north, bounds$south)
    lngRng <- range(bounds$east, bounds$west)
    
    if (input$inMake=='All' ){
      slice<-subset(df,Lat >= latRng[1] & Lat <= latRng[2] &
                      Lng >= lngRng[1] & Lng <= lngRng[2] &
                      Year>= input$inYear[1] & Year<= input$inYear[2] &
                      Price>=(input$inPrice[1]*1000) & Price<=(input$inPrice[2]*1000))
    }else if (input$inMake!='All' & input$inModel=='All'){
      slice<-subset(df,latRng[1] & Lat <= latRng[2] &
                      Lng >= lngRng[1] & Lng <= lngRng[2] &
                      Make==input$inMake  & Year>=input$inYear[1] & Year<=input$inYear[2] & Price>=(input$inPrice[1]*1000) & Price<=(input$inPrice[2]*1000) )  
    }else if (input$inMake!='All' & input$inModel!='All'){
      slice<-subset(df,latRng[1] & Lat <= latRng[2] &
                      Lng >= lngRng[1] & Lng <= lngRng[2] &
                      Make==input$inMake & Model==input$inModel & Year>=input$inYear[1] & Year<=input$inYear[2] & Price>=(input$inPrice[1]*1000) & Price<=(input$inPrice[2]*1000))  
    }
    
  })
  
  #function Filter the data based on brush at the scatter plot
  df_slice_b<-reactive({
    if (is.null(input$plotPrice_brush)){
      return(df_slice())
    }else{
      return(brushedPoints(df_slice(),input$plotPrice_brush) )
    }
  })
  
  ###################################################################################
  #Function to interactivly draw the marker for listings
  DrawMarkers<-reactive({
    
    if (input$inCluster==TRUE) 
    {
      #Draw markers clustered together
      leafletProxy('plotmap',data=df_slice_b()) %>%
        clearShapes() %>%
        clearMarkers()%>%
        clearMarkerClusters()%>%
        addCircleMarkers(
          ~Lng, ~Lat,
          stroke=F,
          fillOpacity=.8,
          popup = ~paste('<strong>Manufacturer:</strong>', Make,
                         '</br><strong>Model:</strong>', Model,
                         '</br><strong>Year:</strong>', Year,
                         '</br><strong>Price:</strong>', Price,'AUD',
                         '</br><strong>URL:</strong>', paste('<a href="',url,'" target="_blank">Go to Gumtree Listing</a>'),
                         '</br><strong>Odometer:</strong>', Km,
                         '</br><strong>Transmision:</strong>', Trans,
                         '</br><strong>Registraion:</strong>', Reg,
                         '</br><strong>Fuel:</strong>', Fuel,
                         '</br><strong>AC:</strong>', AC),
          popupOptions  = labelOptions(noHide = F, direction = 'top', textOnly = T,textsize=9)
          ,color=~pal(PriceCluster)
          ,clusterOptions = markerClusterOptions()
        )
    }
    #Draw individual marker per listing
    if (input$inCluster==FALSE) 
    {
      leafletProxy('plotmap',data=df_slice_b()) %>%
        clearShapes() %>%
        clearMarkers()%>%
        clearMarkerClusters()%>%
        addCircleMarkers(
          ~Lng, 
          ~Lat,
          stroke=F,
          fillOpacity=.8,
          radius=4, 
          popup = ~paste('<strong>Manufacturer:</strong>', Make,
                         '</br><strong>Model:</strong>', Model,
                         '</br><strong>Year:</strong>', Year,
                         '</br><strong>Price:</strong>', Price,'AUD',
                         '</br><strong>URL:</strong>',  paste('<a href="',url,'" target="_blank">Go to Gumtree Listing</a>'),
                         '</br><strong>Odometer:</strong>', Km,
                         '</br><strong>Transmision:</strong>', Trans,
                         '</br><strong>Registraion:</strong>', Reg,
                         '</br><strong>Fuel:</strong>', Fuel,
                         '</br><strong>AC:</strong>', AC),
          color=~pal(PriceCluster)
        )
    }
  })
  
  
  ###################################################################################
  
  
  
  #Populate model drop down list based on Maker selection
  observeEvent(input$inMake,{
    x<-input$inMake
    Models <-unique(Makers_Models[Makers_Models$Make==as.character(x),2])
    updateSelectInput(session, inputId = 'inModel',label = 'Car Model:',choices = c('All',as.character(Models)),selected = 'All')
    DrawMarkers()
    
    
  })
  
  observeEvent(input$plotPrice_click,{
    DrawMarkers()
    })
  observeEvent(input$plotPrice_brush,{ DrawMarkers() })
  observeEvent(input$inYear,{ DrawMarkers() })
  observeEvent(input$inMake,{ DrawMarkers() })
  observeEvent(input$inModel,{ DrawMarkers() })
  observeEvent(input$inPrice,{ DrawMarkers() })
  observeEvent(input$inCluster,{ DrawMarkers() })
  observeEvent(input$plotPrice_click,{DrawMarkers()})
  
  #Draw histogram
  output$histMonth<-renderPlot({
    if (input$in_agg_sel=='CNT'){
      ggplot(data=df_slice_b(), aes(x=DateListed))+geom_bar(aes(y=..count..),fill='light blue')+
        labs(
          x = "Month",
          y = "Cars Count",
          title='Cars Listed Per Month')+
        theme(plot.title = element_text(hjust = 0.5, face='bold'))
    }else if(input$in_agg_sel=='AVG'){
      ggplot(df_slice_b(), aes(x=DateListed, y=Price)) + stat_summary(fun.y="mean", geom="bar",fill='light blue')+
        labs(
          x = "Month",
          y = "average listings price (AUD)",
          title='Average listings Price ')+
        theme(plot.title = element_text(hjust = 0.5, face='bold'))
    }
  })
  #Draw Pric .Vs. Year scatter Plot
  output$plotPrice<-renderPlot({
    ggplot(df_slice(), aes(x=Year, y=Price,colour = PriceCluster)) +
      geom_point() +
      scale_colour_manual(name = "PriceCluster",values = PriceColors)+
      scale_y_continuous(labels = comma)+
      labs(
        x = "Manuf. Year",
        y = "Price(AUD)",
        colour = "Price Cluster",
        title='Price.VS.Age Distribution')+
      theme(legend.position = "bottom")+
      theme(plot.title = element_text(hjust = 0.5,face='bold'))
    
  })
  # Render Table 
    output$mytable <- renderDataTable(df_slice_b())
  
}

shinyApp(ui, server)

