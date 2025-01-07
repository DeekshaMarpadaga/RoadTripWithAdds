library(shiny)
library(httr)
library(dplyr)
library(ggplot2)
library(plotly)
library(lubridate)

# Function to fetch stats from the Flask API
get_stats_data <- function() {
  response <- GET("http://127.0.0.1:5000/api/stats")
  content(response, "parsed")
}

# UI
ui <- dashboardPage(
  dashboardHeader(title = "Trip Statistics"),
  dashboardSidebar(),
  dashboardBody(
    fluidRow(
      valueBoxOutput("totalTrips"),
      valueBoxOutput("totalDistance"),
      valueBoxOutput("totalTime")
    ),
    fluidRow(
      box(title = "Trips Overview", status = "primary", solidHeader = TRUE, width = 12,
          plotlyOutput("tripPlot"))
    )
  )
)

# Server Logic
server <- function(input, output) {
  # Fetch stats data from Flask API
  stats <- reactive({
    get_stats_data()
  })
  
  # Fetch trip data for plotting
  trip_data <- reactive({
    response <- GET("http://127.0.0.1:5000/api/trip_data")
    trip_content <- content(response, "parsed")  # Parse the JSON content into a list or data frame
    return(trip_content)  # Return the parsed trip data
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
  
}
# Run the app
shinyApp(ui = ui, server = server)
