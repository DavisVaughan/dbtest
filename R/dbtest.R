#' @import dplyr
#' @import testthat
#' @import purrr
#' @import htmltools
#' @import utils
#' @import pracma
#' @export
test_database <- function(databases = "", configuration =  "default", directory = ""){
  original_configuration <- Sys.getenv("R_CONFIG_ACTIVE")
  if(is.null(configuration)==FALSE) Sys.setenv(R_CONFIG_ACTIVE = configuration)

  all_results <- databases %>%
    map(function(.x)run_script(.x, test_directory = directory))

  text_results <- 1:length(databases) %>%
    map(function(x){
      1:length(all_results[[x]]) %>%
        map(function(y)all_results[[x]][[y]]$results[[1]]$message)
    })

  text_call<- 1:length(databases) %>%
    map(function(x){
      1:length(all_results[[x]]) %>%
        map(function(y)all_results[[x]][[y]]$results[[1]]$call[[1]])
    })

  new_results <- all_results %>%
    map(as.data.frame)

  new_results <- 1:length(databases) %>%
    map(function(.x)mutate(new_results[[.x]],
                           database = databases[.x],
                           result = as.character(text_results[[.x]]),
                           call = as.character(text_call[[.x]])
    )
    ) %>%
    bind_rows() %>%
    mutate(res = ifelse(failed == 0 & error == FALSE, "Passed" , "Failed")) %>%
    arrange(desc(database))

  Sys.setenv(R_CONFIG_ACTIVE = original_configuration)

  new_results
}


#' @export
html_report <- function(
  results_variable,
  filename = "dplyr_test_results.html",
  title = "dplyr SQL translation tests",
  show_when_complete = TRUE
  ){

  html_result <- list(
    tags$h1(title) ,
    1:nrow(results_variable) %>%
      map(function(x){
        print_result(results_variable[x,], x)
      }))

  save_html(html_result, filename)

  if(show_when_complete)utils::browseURL(filename)
}

print_result <- function(record, id){
  list(
    tags$h3(tags$strong(paste0(id,  " - " , record$database, " - Test: ", record$test ))),
    tags$table(
      tags$tr(
        tags$td(tags$strong("")),
        tags$td(tags$strong("File:")),
        tags$td(record$file),
        tags$td(tags$strong("Result:"),
                if(record$failed == 0){
                  paste0("Passed", if(record$error)" had error(s)")
                } else
                {"Failed"},
                colspan = 2
        ),
        tags$td(tags$strong("Runtime (In Secs.):  "), round(record$real, digits = 2), colspan = 2)
      ),
      tags$tr(tags$td(tags$p(""))),

      tags$tr(
        tags$td(tags$p("")),
        tags$td(tags$strong("Test Message:"), colspan = 5)
      ),
      tags$tr(
        tags$td(tags$p(""), colspan = 2),
        tags$td(record$result, colspan = 4)
      ),
      tags$tr(tags$td(tags$p(""))),

      tags$tr(
        tags$td(tags$p("")),
        tags$td(tags$strong("Call:"), colspan = 5)
      ),
      tags$tr(
        tags$td(tags$p(""), colspan = 2),
        tags$td(record$call, colspan = 4)
      )

    ),
    tags$br(),
    tags$hr(),
    tags$br()
  )
}


run_script <- function(connection_name, test_directory){

  # Swtiching between local project and installed package location

  if(test_directory==""){
    test_directory <- file.path(system.file(package = "dbtest"), "sql-tests")
  } else {
    test_directory <- file.path(rprojroot::find_rstudio_root_file(), test_directory)
  }


  if(connection_name==""){

    con <<- DBI::dbConnect(RSQLite::SQLite(), path = ":memory:")
  } else {
    db <- config::get(connection_name)

    con <<- DBI::dbConnect(
      odbc::odbc(),
      Driver = db$Driver,
      Server = db$Server,
      Host = db$Host,
      SVC = db$SVC,
      Database = db$Database,
      Schema = db$Schema,
      UID  = db$UID,
      PWD = db$PWD,
      Port = db$Port,
      dsn = db$dsn)
  }

  results <- testthat::test_dir(test_directory, reporter = "minimal")

  DBI::dbDisconnect(con)

  return(results)
}




