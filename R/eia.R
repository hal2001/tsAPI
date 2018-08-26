#' EIA API Category Query
#' @export eia_query
#' @description A function to pull the available categories in the eia API
#' @param api_key A character, the user API key for the eia website
#' @param category_id A character, the category ID as defined in the eia API
#' @return A list, with the series metadata


eia_query <- function(api_key, category_id = NULL){
  url <- get <- output <- NULL
  url <- paste("http://api.eia.gov/category/?api_key=", api_key, sep = "")
  if(!base::is.null(category_id)){
    url <- base::paste(url, "&category_id=", category_id, "&", sep = "")
  }

  get <- httr::GET(url = url)
  output <- jsonlite::fromJSON(httr::content(get, as = "text"))
  return(output)
}

#' EIA API Series Query
#' @export eia_series
#' @description A function to pull a series from the eia API based on series ID
#' @param api_key A character, the user API key for the eia website
#' @param series_id A character, the series ID as defined in the eia API,
#' to query for the available series IDs use the eia_query function
#' @return A list, with the series metadata

eia_series <- function(api_key, series_id){
  url <- get <- output <- NULL
  url <- paste("http://api.eia.gov/series/?series_id=", series_id, "&api_key=", api_key, sep = "")
  get <- httr::GET(url = url)
  output <- jsonlite::fromJSON(httr::content(get, as = "text"))
  return(output)
}


#' Parse a EIA Output
#' @export eia_parse
#' @description A parsing function for series from the EIA API
#' @param raw_series A list, the EIA API output for series request using the eia_series function
#' @param type A character, define the class of the output, possible options c("xts", "zoo", "ts", "data.frame", "data.table", "tbl")
#' @return A time series object according to the type argument setting

eia_parse <- function(raw_series, type = "xts"){
  date <- raw_series$series$data[[1]][,1]
  data <- raw_series$series$data[[1]][,2]
  if(type == "xts"){
    if(raw_series$series$f == "M"){
      output <- xts::xts(x =  base::as.numeric(data), order.by =  zoo::as.yearmon(date))
    } else if (raw_series$series$f == "Q"){
      output <- xts::xts(x =  base::as.numeric(data), order.by =  zoo::as.yearqtr(date))
    } else if (raw_series$series$f == "A"){
      output <- xts::xts(x =  base::as.numeric(data), order.by =
                           lubridate::ymd(base::paste(base::as.numeric(date), "01-01", sep = "")))
    }
  } else if(type == "zoo"){
    if(raw_series$series$f == "M"){
      output <- zoo::zoo(x =  base::as.numeric(data), order.by =  zoo::as.yearmon(date))
    } else if (raw_series$series$f == "Q"){
      output <- zoo::zoo(x =  base::as.numeric(data), order.by =  zoo::as.yearqtr(date))
    } else if (raw_series$series$f == "A"){
      output <- zoo::zoo(x =  base::as.numeric(data), order.by =
                           lubridate::ymd(base::paste(base::as.numeric(date), "01-01", sep = "")))
    }
  } else if(type == "ts"){
    if(raw_series$series$f == "M"){
      df <- data.frame(data = base::as.numeric(data),
                       date = zoo::as.yearmon(date)) %>% dplyr::arrange(date)
      start_date <- zoo::as.Date.yearmon(min(df$date))
      output <- stats::ts(data =  df$data,
                          start = c(lubridate::year(start_date), lubridate::month(start_date)),
                          frequency = 12)
    } else if (raw_series$series$f == "Q"){
      df <- data.frame(data = base::as.numeric(data),
                       date = zoo::as.yearqtr(date)) %>% dplyr::arrange(date)
      start_date <- zoo::as.Date.yearqtr(min(df$date))
      output <- stats::ts(data =  df$data,
                          start = c(lubridate::year(start_date), lubridate::quarter(start_date)),
                          frequency = 4)
    } else if (raw_series$series$f == "A"){
      df <- data.frame(data = base::as.numeric(data),
                       date = base::as.numeric(date)) %>% dplyr::arrange(date)

      output <- stats::ts(data =  df$data,
                          start = base::min(df$date),
                          frequency = 1)
    }
  } else if(type %in% c("data.frame", "data.table", "tbl")){
    if(raw_series$series$f == "M"){
      df <- data.frame(data = base::as.numeric(data),
                       date = zoo::as.yearmon(date)) %>% dplyr::arrange(date)
    } else if (raw_series$series$f == "Q"){
      df <- data.frame(data = base::as.numeric(data),
                       date = zoo::as.yearqtr(date)) %>% dplyr::arrange(date)
    } else if (raw_series$series$f == "A"){
      df <- data.frame(data = base::as.numeric(data),
                       date = base::as.numeric(date)) %>% dplyr::arrange(date)
    }

    if(type == "data.frame"){
      output <- df
    } else if(type == "data.table"){
      output <- data.table::as.data.table(df)
    } else if(type == "tbl"){
      output <- dplyr::as.tbl(df)
    }
  }

  return(output)
}
