suppressPackageStartupMessages(library('RMySQL'))
suppressPackageStartupMessages(library('mongolite'))
suppressPackageStartupMessages(library('tidyr'))
suppressPackageStartupMessages(library('dplyr'))
suppressPackageStartupMessages(library('purrr'))

mysqlDB <- 
  DBI::dbConnect(
    RMySQL::MySQL(), 
    dbname = Sys.getenv("DB_DATABASE"), 
    host = Sys.getenv("DB_HOST"), 
    user = Sys.getenv("DB_USERNAME"), 
    port = suppressWarnings(as.integer(Sys.getenv("DB_PORT"))),
    password = Sys.getenv("DB_PASSWORD"))


#dbListTables(mysqlDB)

start_time <- Sys.time()

print("Querying MySQL Database...")

ordersQuery <- "SELECT o.id, o.order_date, o.shipper, o.consignee, o.carrier,
            o.tracking, o.total_price, o.purchase_detail, o.created_at,
            s.status, s.abbreviation, 
            u.citizen_card, u.first_name, u.last_name, u.email FROM orders o 
            INNER JOIN order_statuses s ON o.status_id = s.id
            INNER JOIN users u ON o.customer_id = u.id"

orders <- dbGetQuery(mysqlDB, ordersQuery)

dbDisconnect(mysqlDB)

#nrow(orders)
#head(orders)

print("Mapping data...")
ordersNested <- as_tibble(orders) %>% nest(status = c(status, abbreviation), user = c(citizen_card, first_name, last_name, email))

ordersNested <- ordersNested %>% mutate(status = purrr::map(status, as.list), user =  purrr::map(user, as.list)) %>% jsonlite::toJSON(auto_unbox = TRUE, pretty = TRUE) 

#head(ordersNested)
#ordersNested %>% select(status, user)

mongoURI <- paste("mongodb://", 
              Sys.getenv("MONGO_DB_USERNAME"), 
              ":", 
              Sys.getenv("MONGO_DB_PASSWORD"), 
              "@", 
              Sys.getenv("MONGO_DB_HOST"), 
              ":", 
              Sys.getenv("MONGO_DB_PORT"),
              sep = "")
       

mongdoDBOrders <- mongo(collection = "orders", db = Sys.getenv("MONGO_DB_NAME"), url = mongoURI,
verbose = FALSE, options = ssl_options())

print("Migrating to Mongo Database...")

mongdoDBOrders$insert(jsonlite::fromJSON(ordersNested))

end_time <- Sys.time()

end_time - start_time

print("Done!")