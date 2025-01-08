library(shiny)
library(shinydashboard)
library(httr)
library(dplyr)
library(ggplot2)
library(plotly)
library(lubridate)
library(leaflet)
library(shinyjs)  # Required for JavaScript functionality

# Function to fetch stats from the Flask API
get_stats_data <- function() {
  response <- GET("http://127.0.0.1:5000/api/stats")
  content(response, "parsed")
}

# Function to fetch trip data for plotting
get_trip_data <- function() {
  response <- GET("http://127.0.0.1:5000/api/trip_data")
  content(response, "parsed")
}

# Function to fetch location data for mapping
get_location_data <- function() {
  response <- GET("http://127.0.0.1:5000/api/locations")
  content(response, "parsed")
}

# UI
ui <- dashboardPage(
  dashboardHeader(title = "Trip Statistics"),
  dashboardSidebar(),
  dashboardBody(
    useShinyjs(),  # Initialize shinyjs
    fluidRow(
      # Back to Index Button
      actionButton("back_btn", "Home", class = "btn btn-primary")
    ),
    fluidRow(
      valueBoxOutput("totalTrips"),
      valueBoxOutput("totalDistance"),
      valueBoxOutput("totalTime")
    ),
    fluidRow(
      box(title = "Trips Overview", status = "primary", solidHeader = TRUE, width = 12,
          plotlyOutput("tripPlot"))
    ),
    fluidRow(
      box(title = "Locations", status = "primary", solidHeader = TRUE, width = 12,
          leafletOutput("locationMap", height = 400))
    )
    
  )
)

# Server Logic
server <- function(input, output, session) {
  
  # Fetch stats data from Flask API
  stats <- reactive({
    get_stats_data()
  })
  
  # Fetch trip data for plotting
  trip_data <- reactive({
    get_trip_data()
  })
  
  # Fetch location data for mapping
  location_data <- reactive({
    get_location_data()
  })
  
  # Display statistics in value boxes
  output$totalTrips <- renderValueBox({
    valueBox(
      value = stats()$total_trips,
      subtitle = "Total Trips",
      icon = icon("car"),
      color = "aqua"
    )
  })
  
  output$totalDistance <- renderValueBox({
    valueBox(
      value = round(stats()$total_distance, 2),
      subtitle = "Total Distance (mi)",
      icon = icon("road"),
      color = "green"
    )
  })
  
  output$totalTime <- renderValueBox({
    valueBox(
      value = stats()$total_time,
      subtitle = "Total Duration",
      icon = icon("clock"),
      color = "red"
    )
  })
  
  # Plotting Trip Data
  output$tripPlot <- renderPlotly({
    # Fetch trip data
    trips <- trip_data()
    
    # If there's no data, return NULL
    if (length(trips) == 0 || is.null(trips)) {
      return(NULL)
    }
    
    # Combine all trips into a single data frame
    trip_df_list <- lapply(trips, function(trip) {
      data.frame(
        month = ym(trip$month),  # Convert 'month' to Date format (Year-Month)
        total_distance = as.numeric(trip$total_distance)
      )
    })
    
    # Combine the list of data frames into one data frame
    trip_df <- do.call(rbind, trip_df_list)
    
    # Remove any rows with NA or infinite values
    trip_df <- trip_df %>%
      filter(!is.na(month), !is.na(total_distance), is.finite(total_distance))
    
    # Check if there's any valid data left to plot
    if (nrow(trip_df) == 0) {
      return(NULL)
    }
    
    # Group by month and sum the total distance for each month
    trip_df_monthly <- trip_df %>%
      group_by(month) %>%
      summarise(total_distance = sum(total_distance), .groups = "drop")
    
    # Sort by month to ensure the months are ordered correctly
    trip_df_monthly <- trip_df_monthly %>%
      arrange(month)
    
    # Plotting
    plot <- ggplot(trip_df_monthly, aes(x = month, y = total_distance)) +
      geom_line(color = "blue", size = 1) +
      geom_point(color = "red") +
      labs(title = "Miles Traveled Per Month", x = "Month", y = "Total Distance (mi)") +
      theme_minimal()
    
    # Convert ggplot to plotly and return the plot
    ggplotly(plot)
  })
  
  # Modify the render function for location map
  output$locationMap <- renderLeaflet({
    # Fetch location data
    locations <- location_data()
    
    # Flatten the list of locations and keep only non-empty addresses
    addresses <- unlist(lapply(locations, function(location) {
      valid_addresses <- location[location != ""]
      return(valid_addresses)
    }))
    
    # Geocode the addresses to get latitude and longitude
    address_df <- data.frame(address = addresses)
    location_df <- geocode(address_df, address = "address")
    
    # Filter out invalid locations
    location_df <- location_df %>%
      filter(!is.na(lat) & !is.na(long))
    
    # Create the map
    leaflet(location_df) %>%
      addProviderTiles(providers$OpenStreetMap) %>%
      addMarkers(lng = ~long, lat = ~lat, popup = ~address)
  })
  
  # Add functionality for the "Back to Index" button
  observeEvent(input$back_btn, {
    runjs('window.location.href = "http://127.0.0.1:5000/";')  # Redirect to Flask index
  })
}

# Run the app
shinyApp(ui = ui, server = server)


