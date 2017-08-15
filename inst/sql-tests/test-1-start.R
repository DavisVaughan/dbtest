context("initialize")

test_data <- function(){
  data <- dbtest::testdata
  data$fld_double <- as.double(data$fld_double)
  data$fld_character <- as.character(data$fld_character)
  data
}

table_name <<- dbplyr:::random_table_name()

test_table <<- test_data()

test_that("copy_to()",{
  expect_silent({
    dbplyr::db_copy_to(con = con, table = table_name, values = test_table, temporary = FALSE,
                   types = c(fld_factor = "VARCHAR",
                             fld_datetime = "DATETIME",
                             fld_date = "DATETIME",
                             fld_time = "VARCHAR",
                             fld_binary = "LONG",
                             fld_integer = "LONG",
                             fld_double = "DOUBLE",
                             fld_character = "VARCHAR",
                             fld_logical = "LONG"
                             ))
  })
})

db_test_table <<- dplyr::tbl(con, table_name)




