## app.R ##
library(devtools)
library(usethis)
library(rsconnect)
library(shiny)
library(shinydashboard)
library(plotly)
library(ggplot2)
library(DT)
library(tidyr)
library(ECharts2Shiny)
library(shinyalert)
library(shinycssloaders)

CEnergy <- read.csv("Chicago_Energy.csv")

# Clean data script by removing incomplete reords
na.FindAndRemove <- function(mydata){
    # We need to find the number of na's per row. Write code that would loop through each column and find if the number of NAs is equal to the number # of rows and then remove any column with all NA's
    for (i in NCOL(mydata)) 
    {
        if (nrow(mydata[i]) == sum(sapply(mydata[i], is.na))) 
        {
            mydata <- mydata[-i]
        }
    }
    mydata <- na.omit(mydata)
    return(mydata)
}



#Pull Column names as list to input in dashboard
columns <- as.data.frame(colnames(CEnergy))
#View(columns)

columns.list <- split(columns, seq(nrow(columns)), rownames(columns))


column.names.y <- c("KWH.JANUARY.2010", "KWH.FEBRUARY.2010", "KWH.MARCH.2010", "KWH.APRIL.2010", "KWH.MAY.2010", "KWH.JUNE.2010", "KWH.JULY.2010", "KWH.AUGUST.2010",
                  "KWH.SEPTEMBER.2010", "KWH.OCTOBER.2010", "KWH.NOVEMBER.2010", "KWH.DECEMBER.2010", "TOTAL.KWH", "THERM.JANUARY.2010", "THERM.FEBRUARY.2010", "THERM.MARCH.2010", "THERM.APRIL.2010",
                  "THERM.MAY.2010", "THERM.JUNE.2010", "THERM.JULY.2010", "THERM.AUGUST.2010", "THERM.SEPTEMBER.2010", "THERM.OCTOBER.2010", "THERM.NOVEMBER.2010", "THERM.DECEMBER.2010", "TOTAL.THERMS", "KWH.TOTAL.SQFT", "THERMS.TOTAL.SQFT",
                  "KWH.MEAN.2010", "KWH.STANDARD.DEVIATION.2010", "KWH.MINIMUM.2010", "KWH.1ST.QUARTILE.2010", "KWH.2ND.QUARTILE.2010", "KWH.3RD.QUARTILE.2010", "KWH.MAXIMUM.2010", "KWH.SQFT.MEAN.2010", "KWH.SQFT.STANDARD.DEVIATION.2010", "KWH.SQFT.MINIMUM.2010",
                  "KWH.SQFT.1ST.QUARTILE.2010", "KWH.SQFT.2ND.QUARTILE.2010", "KWH.SQFT.3RD.QUARTILE.2010", "KWH.SQFT.MAXIMUM.2010", "THERM.MEAN.2010", "THERM.STANDARD.DEVIATION.2010", "THERM.MINIMUM.2010", "THERM.1ST.QUARTILE.2010", "THERM.2ND.QUARTILE.2010",
                  "THERM.3RD.QUARTILE.2010", "THERM.MAXIMUM.2010", "THERMS.SQFT.MEAN.2010", "THERMS.SQFT.STANDARD.DEVIATION.2010", "THERMS.SQFT.MINIMUM.2010", "THERMS.SQFT.1ST.QUARTILE.2010", "THERMS.SQFT.2ND.QUARTILE.2010", "THERMS.SQFT.3RD.QUARTILE.2010",
                  "THERMS.SQFT.MAXIMUM.2010")


column.names.x <- c("COMMUNITY.AREA.NAME", "CENSUS.BLOCK", "BUILDING.TYPE", "BUILDING_SUBTYPE", "ELECTRICITY.ACCOUNTS"
                    , "ZERO.KWH.ACCOUNTS", "GAS.ACCOUNTS", "TOTAL.POPULATION", "TOTAL.UNITS", "AVERAGE.STORIES"
                    , "AVERAGE.BUILDING.AGE", "AVERAGE.HOUSESIZE", "OCCUPIED.UNITS", "OCCUPIED.UNITS.PERCENTAGE"
                    , "RENTER.OCCUPIED.HOUSING.UNITS", "RENTER.OCCUPIED.HOUSING.PERCENTAGE", "OCCUPIED.HOUSING.UNITS")

column.names.x <- as(column.names.x, "list")
column.names.y <- as(column.names.y, "list")

# Increase maximum upload file size to 0.5 GB
options(shiny.maxRequestSize = 500*1024^2)


ui <-dashboardPage(
    #fluidPage(useShinyalert())
    dashboardHeader(title = "Energy Crawler")
    ## Sidebar content
    ,dashboardSidebar(
        # Create sidebar menu with menu items, Filtering options, and submission button
        sidebarMenu(
            menuItem("Key Performance Indicators" , tabName = "KPIs", icon = icon("balance-scale"))
            ,menuItem("Dashboard", tabName = "dashboard", icon = icon("dashboard"))
            ,uiOutput("Areaname")
            ,uiOutput("Censusblock")
            ,uiOutput("Buildingtype")
            ,uiOutput("Buildingsubtype")
            ,uiOutput("Avgstories")
            ,uiOutput("Avgbldgage")
            ,uiOutput("Avghousesize")
            ,actionButton("submit", label = "Submit")
            )
        )
    ## Body content
    ,dashboardBody(
        tabItems(
            tabItem(tabName = "dashboard"
                    ,fluidRow(
                        tabBox(width = 450, height = 500
                               # Create tab panel to display charts in tab
                               ,tabPanel(title= "Electricity Consumption Overview"
                                         #Add in CSS script to ensure dropdown lists render over other objects
                                         ,tags$head(tags$style(".selectize-dropdown {position: static}"))
                                         ,splitLayout(
                                            # Create plot x axis choice for user selection
                                              selectInput(inputId = "xplot1"
                                                          ,label = "X-axis:"
                                                          ,choices = column.names.x
                                                          ,selected = "COMMUNITY.AREA.NAME"
                                                          )
                                              # Create plot color by choice for user selection
                                             ,selectInput(inputId = "zplot1"
                                                          ,label = "Color by"
                                                          ,choices = column.names.x
                                                          ,selected = "BUILDING.TYPE")
                                             )
                                         , fluidRow(plotlyOutput("plot1") %>% withSpinner(color="#0dc5c1"))
                                         # Select whether to show data table
                                         , fluidRow(checkboxInput(inputId = "show_data"
                                                                  ,label = "Show data table"
                                                                  ,value = TRUE))
                                         # render data table corresponding to charts
                                         , fluidRow(# Add horizontal scroll bar
                                                    div(style = 'overflow-x: scroll'
                                                         # Show data table ---------------------------------------------
                                                         ,DT::dataTableOutput(outputId = "energytable1") %>% withSpinner(color="#0dc5c1")
                                                         )
                                                    )
                                         )
                               ,tabPanel(title= "Heating Consumption Overview"
                                         ,tags$head(tags$style(".selectize-dropdown {position: static}"))
                                         ,splitLayout(
                                             selectInput(inputId = "xplot2"
                                                          ,label = "X-axis:"
                                                          ,choices = column.names.x
                                                          ,selected = "COMMUNITY.AREA.NAME"
                                             )
                                             ,selectInput(inputId = "zplot2"
                                                          ,label = "Color by"
                                                          ,choices = column.names.x
                                                          ,selected = "BUILDING.TYPE")
                                         )
                                         , fluidRow(plotlyOutput("plot2") %>% withSpinner(color="#0dc5c1"))
                                         , fluidRow(checkboxInput(inputId = "show_data"
                                                                  ,label = "Show data table"
                                                                  ,value = TRUE))
                                         , fluidRow(# Add horizontal scroll bar
                                             div(style = 'overflow-x: scroll'
                                                 # Show data table ---------------------------------------------
                                                 ,DT::dataTableOutput(outputId = "energytable2") %>% withSpinner(color="#0dc5c1")
                                             )
                                         )
                                         
                                         )
                               ,tabPanel(title= "Energy Usage Intensity"
                                         ,tags$head(tags$style(".selectize-dropdown {position: static}"))
                                         ,splitLayout(
                                             selectInput(inputId = "xplot3"
                                                          ,label = "X-axis:"
                                                          ,choices = column.names.x
                                                          ,selected = "COMMUNITY.AREA.NAME"
                                             )
                                             ,selectInput(inputId = "zplot3"
                                                          ,label = "Color by"
                                                          ,choices = column.names.x
                                                          ,selected = "BUILDING.TYPE")
                                         )
                                         , fluidRow(plotlyOutput("plot3") %>% withSpinner(color="#0dc5c1"))
                                         , fluidRow(checkboxInput(inputId = "show_data"
                                                                  ,label = "Show data table"
                                                                  ,value = TRUE))
                                         , fluidRow(# Add horizontal scroll bar
                                             div(style = 'overflow-x: scroll'
                                                 # Show data table ---------------------------------------------
                                                 ,DT::dataTableOutput(outputId = "energytable3") %>% withSpinner(color="#0dc5c1")
                                             )
                                         )
                                         
                               )
                               )
                        )
                    )
        , tabItem(tabName = "KPIs"
                  ,fluidRow(textOutput("text1"))
                  ,fluidRow(align = "center"
                      #column(6,
                      # A static valueBox
                      #adjust height of value boxes for presentation
                      ,tags$head(tags$style(HTML(".small-box {height: 300px}")))
                      ,valueBoxOutput("electricconsumption")
                      # Dynamic valueBoxes
                      ,valueBoxOutput("progressBox")
                      ,valueBoxOutput("approvalBox")
                      )
                  )
        
        )
    )
    )
    


server <- function(input, output) {

    # the modal dialog where the user can enter the query details.
    query_modal <- modalDialog(
        title = "Welcome to the Chicago Energy Crawler App"
        ,"To get started please select filter options on the left panel and click submit. Users can then navigate between KPIs and the Dashboard for analysis.",
        #selectInput('input_query','Select # cyl:',unique(mtcars$cyl)),
        easyClose = T,
        fade = T,
        footer = modalButton("Get Started")
    )
    
    # Show the model on start up ...
    showModal(query_modal)
        
    
    CEnergy <- read.csv("Chicago_Energy.csv")
    CEnergy <- na.FindAndRemove(CEnergy)
    # Sample dataset for presentation and performance benefits
    CEnergy <- CEnergy[sample(x = NROW(CEnergy), size = 1000),]
    
    output$Areaname <- renderUI({
        arealist <- sort(unique(as.vector(CEnergy$COMMUNITY.AREA.NAME)), decreasing = FALSE)
        arealist <- append(arealist, "All", after =  0)
        selectizeInput("Areaname", "Area Name:", arealist, multiple = T, selected = "All")
    })
    
    
    output$Censusblock <- renderUI({
        cblocklist <- sort(unique(as.vector(CEnergy$CENSUS.BLOCK)), decreasing = FALSE)
        cblocklist <- append(cblocklist, "All", 0)
        selectizeInput("Censusblock", "Census Block:", cblocklist, multiple = T, selected = "All")
    })
    
    output$Buildingtype <- renderUI({
        Buildingtype <- sort(unique(as.vector(CEnergy$BUILDING.TYPE)), decreasing = FALSE)
        Buildingtype <- append(Buildingtype, "All", 0)
        selectizeInput("Buildingtype", "Building Type:", Buildingtype, multiple = T, , selected = "All")
    })
    
    output$Buildingsubtype <- renderUI({
        Buildingsubtype <- sort(unique(as.vector(CEnergy$BUILDING_SUBTYPE)), decreasing = FALSE)
        Buildingsubtype <- append(Buildingsubtype, "All", 0)
        selectizeInput("Buildingsubtype", "Building Sub-Type:", Buildingsubtype, multiple = T, selected = "All")
    })
    
    output$Avgstories <- renderUI({
        Avgstories <- sort(unique(as.vector(CEnergy$AVERAGE.STORIES)), decreasing = FALSE)
        Avgstories <- append(Avgstories, "All", 0)
        sliderInput("Avgstories"
                    ,"Average Stories:"
                    , min = min(CEnergy$AVERAGE.STORIES)
                    , max = max(CEnergy$AVERAGE.STORIES)
                    , value = c(1,3)
                    , step = 0.1 )
    })
    
    output$Avgbldgage <- renderUI({
        Avgbldgage <- sort(unique(as.vector(CEnergy$AVERAGE.BUILDING.AGE)), decreasing = FALSE)
        Avgbldgage <- append(Avgbldgage, "All", 0)
        sliderInput("Avgbldgage"
                    ,"Average Building Age:"
                    , min = min(CEnergy$AVERAGE.BUILDING.AGE)
                    , max = max(CEnergy$AVERAGE.BUILDING.AGE)
                    , value = c(0,50)
                    , step = 1 )
    })
    
    output$Avghousesize <- renderUI({
        Avghousesize <- sort(unique(as.vector(CEnergy$AVERAGE.HOUSESIZE)), decreasing = FALSE)
        Avghousesize <- append(Avghousesize, "All", 0)
        sliderInput("Avghousesize"
                    ,"Average House Size:"
                    , min = min(CEnergy$AVERAGE.HOUSESIZE)
                    , max = max(CEnergy$AVERAGE.HOUSESIZE)
                    , value = c(1,3)
                    , step = 0.5 )
    })
    
    energy_subset <- eventReactive(eventExpr = input$submit, ({
        req(input$Areaname)
        req(input$Censusblock)
        req(input$Buildingtype)
        req(input$Buildingsubtype)
        req(input$Avgstories)
        req(input$Avgbldgage)
        req(input$Avghousesize)
        
        
        if(input$Areaname == "All") {
            filt1 <- quote(COMMUNITY.AREA.NAME != "@?><")
        } else {
            filt1 <- quote(COMMUNITY.AREA.NAME == input$Areaname) 
        }
        
        if (input$Censusblock == "All") {
            filt2 <- quote(CENSUS.BLOCK != "@?><")
        } else {
            filt2 <- quote(CENSUS.BLOCK == input$Censusblock)
        }
        
        if (input$Buildingtype == "All") {
            filt3 <- quote(BUILDING.TYPE != "@?><")
        } else {
            filt3 <- quote(BUILDING.TYPE == input$Buildingtype)
        }
        
        if (input$Buildingsubtype == "All") {
            filt4 <- quote(BUILDING_SUBTYPE != "@?><")
        } else {
            filt4 <- quote(BUILDING_SUBTYPE == input$Buildingsubtype)
        }
        
        if (input$Avgstories == "All") {
            filt5 <- quote(AVERAGE.STORIES != "@?><")
        } else {
            filt5 <- quote(AVERAGE.STORIES >= min(input$Avgstories) & AVERAGE.STORIES <= max(input$Avgstories))
        }
        
        if (input$Avgbldgage == "All") {
            filt6 <- quote(AVERAGE.BUILDING.AGE != "@?><")
        } else {
            filt6 <- quote(AVERAGE.BUILDING.AGE >= min(input$Avgbldgage) & AVERAGE.BUILDING.AGE <= max(input$Avgbldgage))
        }
        
        if (input$Avghousesize == "All") {
            filt7 <- quote(AVERAGE.HOUSESIZE != "@?><")
        } else {
            filt7 <- quote(AVERAGE.HOUSESIZE >= min(input$Avghousesize) & AVERAGE.HOUSESIZE <= max(input$Avghousesize))
        }
        
        CEnergy %>%
            filter_(filt1) %>%
            filter_(filt2) %>%
            filter_(filt3) %>%
            filter_(filt4) %>%
            filter_(filt5) %>%
            filter_(filt6) %>%
            filter_(filt7)
    }))
    
    
    
    # I tried really hard here to have a reactive summarisation of data to the reactively filtered data
    # I could not however figure out how to get R to reference the data represented by the x-axis selection rather than the name of the x-axis
    # plot1df <- reactive({
    #     energy_subset() %>%
    #     group_by(input$xplot1) %>%
    #     summarise(EUI = mean(TOTAL.KWH/KWH.TOTAL.SQFT))
    # })
    # 
    # plot2df <- reactive({
    #     energy_subset() %>% 
    #         group_by(input$xplot2) %>% 
    #         summarise(TotalTherms = sum(TOTAL.THERMS))
    # })
    # 
    # plot3df <- reactive({
    #     energy_subset() %>% 
    #         group_by(input$xplot3) %>% 
    #         summarise(EUI = mean(TOTAL.KWH/KWH.TOTAL.SQFT)) 
    # })
    
    #Debugging script
    #print(class(plot1df))
    #print(class(energy_subset))
    #output$text1 <- renderText(print(plot1df()))
        
    # Create scatterplot object for energy usage 
    output$plot1 <- renderPlotly({
        ggplotly(
            ggplot(data = energy_subset(), aes_string(x = input$xplot1, y = energy_subset()$TOTAL.KWH/1000, color = input$zplot1))
            +geom_area()
            +labs(x= input$xplot1, y = "Total Consumption (MWH)")
            +theme(axis.text.x = element_text(angle = 90))
            )
    })
    
    # Create scatterplot object the plotOutput function is expecting --
    output$plot2 <- renderPlotly({
        ggplotly(
            ggplot(data = energy_subset(), aes_string(x = input$xplot2, y = energy_subset()$TOTAL.THERMS/1000, color = input$zplot2))
            +geom_point( )
            +labs(x= input$xplot2, y = "Total Heating Consumption (MTherms)")
            +theme(axis.text.x = element_text(angle = 90))
        )
    })
    
    # Create scatterplot object the plotOutput function is expecting --
    output$plot3 <- renderPlotly({
        ggplotly(
            ggplot(data = energy_subset(), aes_string(x = input$xplot3, y = energy_subset()$TOTAL.KWH/energy_subset()$KWH.TOTAL.SQFT, color = input$zplot3))
            +geom_boxplot() 
            +labs(x= input$xplot3, y = "Energy Usage Intensity (kWH/sqft)")
            +theme(axis.text.x = element_text(angle = 90))
        )
    })
    
    
    output$progressBox <- renderValueBox({
        valueBox(
            paste0(length(unique(energy_subset()$COMMUNITY.AREA.NAME))), "Neighbourhoods", icon = icon("home")
            ,color = "purple"
        )
    })
    
    output$approvalBox <- renderValueBox({
        valueBox(round(sum(energy_subset()$TOTAL.THERMS)/1000, 2), "Thermal Consumption (MTherms)", icon = icon("fire")
                 ,color = "red"
        )
    })
    
    output$electricconsumption <- renderValueBox({
        valueBox(round(sum(energy_subset()$TOTAL.KWH)/1000000, 2), "Electric Consumption (GWH)", icon = icon("bolt")
                 ,color = "yellow"
        )
    })
    
    # Print data table if checked -------------------------------------
    output$energytable1 <- DT::renderDataTable(
        if(input$show_data){
                DT::datatable(data = energy_subset()
                          # Enable Buttons --------------------------------
                          ,extensions = 'Buttons'
                          ,options = list(pageLength = 10,
                                         # Turn off search ----------------
                                         dom = "Btp",
                                         # Buttons available --------------
                                         buttons = c('copy', 'csv', 'excel', 'pdf', 'print')
                                         )
                          ,rownames = FALSE
                          )  %>% 
                
                # Format text example ---------------------------------------
            formatStyle(
                columns = 5, 
                valueColumns = 5, 
                color = styleEqual(c("R","G", "PG", "PG-13"), c("red", "green", "blue", "yellow"))
            ) %>%
                
                # Format background example ---------------------------------
            formatStyle(
                columns = 8,
                #background = styleColorBar(range(CEnergy), '#cab2d6'),
                backgroundSize = '90% 85%',
                backgroundRepeat = 'no-repeat',
                backgroundPosition = 'center')
        }
    )

    
    # Print data table if checked -------------------------------------
    output$energytable2 <- DT::renderDataTable(
        if(input$show_data){
            DT::datatable(data = energy_subset()
                          # Enable Buttons --------------------------------
                          ,extensions = 'Buttons'
                          ,options = list(pageLength = 10,
                                          # Turn off search ----------------
                                          dom = "Btp",
                                          # Buttons available --------------
                                          buttons = c('copy', 'csv', 'excel', 'pdf', 'print')
                          )
                          ,rownames = FALSE
                          #,style = "height:500px; overflow-y: scroll;overflow-x: scroll;"
            )  %>% 
                
                # Format text example ---------------------------------------
            formatStyle(
                columns = 5, 
                valueColumns = 5, 
                color = styleEqual(c("R","G", "PG", "PG-13"), c("red", "green", "blue", "yellow"))
            ) %>%
                
                # Format background example ---------------------------------
            formatStyle(
                columns = 8,
                #background = styleColorBar(range(CEnergy), '#cab2d6'),
                backgroundSize = '90% 85%',
                backgroundRepeat = 'no-repeat',
                backgroundPosition = 'center')
        }
    )
    
    # Print data table if checked -------------------------------------
    output$energytable3 <- DT::renderDataTable(
        if(input$show_data){
            DT::datatable(data = energy_subset()
                          # Enable Buttons --------------------------------
                          ,extensions = 'Buttons'
                          ,options = list(pageLength = 10,
                                          # Turn off search ----------------
                                          dom = "Btp",
                                          # Buttons available --------------
                                          buttons = c('copy', 'csv', 'excel', 'pdf', 'print')
                          )
                          ,rownames = FALSE
                          #,style = "height:500px; overflow-y: scroll;overflow-x: scroll;"
            )  %>% 
                
                # Format text example ---------------------------------------
            formatStyle(
                columns = 5, 
                valueColumns = 5, 
                color = styleEqual(c("R","G", "PG", "PG-13"), c("red", "green", "blue", "yellow"))
            ) %>%
                
                # Format background example ---------------------------------
            formatStyle(
                columns = 8,
                #background = styleColorBar(range(CEnergy), '#cab2d6'),
                backgroundSize = '90% 85%',
                backgroundRepeat = 'no-repeat',
                backgroundPosition = 'center')
        }
    )    
    
}

shinyApp(ui, server)