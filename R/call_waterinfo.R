
waterinfo_base <- function() {
    "http://download.waterinfo.be/tsmdownload/KiWIS/KiWIS"
}
waterinfo_pro_base <- function() {
    "http://pro.waterinfo.be/tsmpro/KiWIS/KiWIS"
}

#' http call to waterinfo.be
#'
#' General call used to request information and data from waterinfo.be,
#' providing error handling and json parsing
#'
#' @param query list of query options to be used together with the base string
#' @param base_url str download | pro, default download defined
#' @param token token to use with the call (optional, can be retrieved via
#' \code{\link{get_token}})
#'
#' @return waterinfo_api class object with content and info about call
#'
#' @export
#' @importFrom httr GET http_type status_code http_error content add_headers
#' @importFrom jsonlite fromJSON
call_waterinfo <- function(query, base_url = "download", token = NULL) {

    # check the base url, which depends of the query to execute
    if (base_url == "download") {
        base  <- waterinfo_base()
    } else if (base_url == "pro") {
        base  <- waterinfo_pro_base()
    } else {
        stop("Base url should be download or pro")
    }

    if (is.null(token)) {
        res <- GET(base, query = query)
    } else {
        if (inherits(token,'token')) {
            res <- GET(base, query = query,
                       config = add_headers(
                           'Authorization' = paste0(attr(token,'type'),
                                                    ' ', token)))
        } else {
            stop("Token must be object of class token, retrieve a token
                 via function get.token")
        }
    }

    if (http_type(res) != "application/json") {
        if (http_type(res) != "application/xml") {
            custom_error <- content(res, "text", encoding = "UTF-8")
            pattern <- "(?<=ExceptionText>).*(?=</ExceptionText>)"
            error_message <- regmatches(custom_error,
                                        regexpr(pattern, custom_error,
                                                perl = TRUE))
        }
        stop("API did not return json - ", error_message, call. = FALSE)
    }

    parsed <- fromJSON(content(res, "text"))

    if (http_error(res)) {
        stop(
            sprintf(
                "Waterinfo API request failed [%s]\nWaterinfo %s:
                %s\nWaterinfo return message: %s",
                status_code(res),
                parsed$type,
                parsed$code,
                parsed$message
            ),
            call. = FALSE
        )
    }

    structure(
        list(
            content = parsed,
            path = strsplit(res$url, "\\?")[[1]][2],
            response = res
        ),
        class = "waterinfo_api"
    )
}


#' Custom print function of the API request response
#'
#' @param x waterinfo_api
#' @param ... args further arguments passed to or from other methods.
#'
#' @export
#'
print.waterinfo_api <- function(x, ...) {
    cat("Waterinfo API query applied: ", x$path, "\n", sep = "")
    str(x$content)
    invisible(x)
}
