#' Create a tibble containing date formats
#'
#' @importFrom dplyr tribble
#' @noRd
date_formats <- function() {

  dplyr::tribble(
    ~format_number, ~format_name,           ~format_code,
    "1",	          "iso",                  "%F",
    "2",	          "wday_month_day_year",  "%A, %B %d, %Y",
    "3",	          "wd_m_day_year",        "%a, %b %d, %Y",
    "4",	          "wday_day_month_year",  "%A %d %B %Y",
    "5",	          "month_day_year",       "%B %d, %Y",
    "6",	          "m_day_year",           "%b %d, %Y",
    "7",	          "day_m_year",           "%d %b %Y",
    "8",	          "day_month_year",       "%d %B %Y",
    "9",	          "day_month",            "%d %B",
    "10",	          "year",                 "%Y",
    "11",	          "month",                "%B",
    "12",	          "day",                  "%d",
    "13",	          "year.mn.day",          "%Y/%m/%d",
    "14",	          "y.mn.day",             "%y/%m/%d")
}

#' Create a tibble containing time formats
#'
#' @importFrom dplyr tribble
#' @noRd
time_formats <- function() {

  dplyr::tribble(
    ~format_number, ~format_name, ~format_code,
    "1",	          "hms",        "%H:%M:%S",
    "2",	          "hm",         "%H:%M",
    "3",	          "hms_p",      "%I:%M:%S %P",
    "4",	          "hm_p",       "%I:%M %P",
    "5",	          "h_p",        "%I %P")
}

#' Transform a `date_style` to a `date_format`
#'
#' @importFrom dplyr filter pull
#' @noRd
get_date_format <- function(date_style) {

  # Create bindings for specific variables
  format_number <- format_code <- format_name <- NULL

  if (date_style %in% 1:14 | date_style %in% as.character(1:14)) {

    return(
      date_formats() %>%
        dplyr::filter(format_number == as.character(date_style)) %>%
        dplyr::pull(format_code))
  }

  if (date_style %in% date_formats()$format_name) {
    return(
      date_formats() %>%
        dplyr::filter(format_name == date_style) %>%
        dplyr::pull(format_code))
  }
}

#' Transform a `time_style` to a `time_format`
#'
#' @importFrom dplyr filter pull
#' @noRd
get_time_format <- function(time_style) {

  # Create bindings for specific variables
  format_number <- format_code <- format_name <- NULL

  if (time_style %in% 1:5 | time_style %in% as.character(1:5)) {

    return(
      time_formats() %>%
        dplyr::filter(format_number == as.character(time_style)) %>%
        dplyr::pull(format_code))
  }

  if (time_style %in% time_formats()$format_name) {
    return(
      time_formats() %>%
        dplyr::filter(format_name == time_style) %>%
        dplyr::pull(format_code))
  }
}

#' Transform a `currency` code to a currency string
#'
#' @importFrom dplyr filter pull
#' @noRd
get_currency_str <- function(currency,
                             fallback_to_code = FALSE) {

  # Create bindings for specific variables
  curr_symbol <- symbol <- curr_code <- curr_number <- NULL

  if (currency[1] %in% currency_symbols$curr_symbol) {

    return(
      currency_symbols %>%
        dplyr::filter(curr_symbol == currency) %>%
        dplyr::pull(symbol))

  } else if (currency[1] %in% currencies$curr_code) {

    currency_symbol <-
      currencies %>%
      dplyr::filter(curr_code == currency) %>%
      dplyr::pull(symbol)

    if (fallback_to_code && grepl("&#", currency_symbol)) {

      currency_symbol <-
        currencies %>%
        dplyr::filter(curr_code == currency) %>%
        dplyr::pull(curr_code)
    }

    return(currency_symbol)

  } else if (currency[1] %in% currencies$curr_number) {

    currency_symbol <-
      currencies %>%
      dplyr::filter(curr_number == currency) %>%
      dplyr::pull(symbol)

    if (fallback_to_code && grepl("&#", currency_symbol)) {

      currency_symbol <-
        currencies %>%
        dplyr::filter(curr_number == currency) %>%
        dplyr::pull(curr_code)
    }

    return(currency_symbol)

  } else {
    return(NA)
  }
}

#' Get a currency exponent from a currency code
#'
#' @importFrom dplyr filter pull
#' @noRd
get_currency_exponent <- function(currency) {

  # Create bindings for specific variables
  curr_code <- curr_number <- NULL

  if (currency[1] %in% currencies$curr_code) {

    exponent <-
      currencies %>%
      dplyr::filter(curr_code == currency) %>%
      dplyr::pull(exponent)

  } else if (currency[1] %in% currencies$curr_number) {

    exponent <-
      currencies %>%
      dplyr::filter(curr_number == currency) %>%
      dplyr::pull(exponent)
  }

  if (is.na(exponent)) {
    return(0L)
  } else {
    return(exponent %>% as.integer())
  }
}

#' Process text based on rendering context any applied classes
#'
#' If the incoming text has the class `from_markdown` (applied by the `md()`
#' helper function), then the text will be sanitized and transformed to HTML
#' from Markdown. If the incoming text has the class `html` (applied by `html()`
#' helper function), then the text will be seen as HTML and it won't undergo
#' sanitization
#' @importFrom stringr str_replace_all
#' @importFrom htmltools htmlEscape
#' @importFrom commonmark markdown_html
#' @noRd
process_text <- function(text,
                         context = "html") {

  # If text is marked `AsIs` (by using `I()`) then just
  # return the text unchanged
  if (inherits(text, "AsIs")) {
    return(text)
  }

  if (context == "html") {

    # Text processing for HTML output

    if (inherits(text, "from_markdown")) {

      text <-
        text %>%
        as.character() %>%
        htmltools::htmlEscape() %>%
        commonmark::markdown_html() %>%
        stringr::str_replace_all("^<p>|</p>|\n", "")

      return(text)

    } else if (is.html(text)) {

      text <- text %>% as.character()

      return(text)

    } else {

      text <- text %>%
        as.character() %>%
        htmltools::htmlEscape()

      return(text)
    }
  } else if (context == "latex") {

    # Text processing for LaTeX output

    if (inherits(text, "from_markdown")) {

      text <- text %>%
        markdown_to_latex()

      return(text)

    } else if (is.html(text)) {

      text <- text %>% as.character()

      return(text)

    } else {

      text <- text %>% escape_latex()

      return(text)
    }
  } else {

    # Text processing in the default case

    if (inherits(text, "from_markdown")) {

      text <- text %>%
        markdown_to_text()

      return(text)

    } else if (is.html(text)) {

      text <- text %>% as.character()

      return(text)

    } else {

      text <- text %>%
        as.character() %>%
        htmltools::htmlEscape()

      return(text)
    }
  }
}

#' Reverse HTML escaping
#'
#' Find common HTML entities resulting from HTML escaping and restore them back
#' to ASCII characters
#' @noRd
unescape_html <- function(text) {

  text %>%
    tidy_gsub("&lt;", "<") %>%
    tidy_gsub("&gt;", ">") %>%
    tidy_gsub("&amp;", "&")
}

#' Transform Markdown text to HTML and also perform HTML escaping
#'
#' @importFrom commonmark markdown_html
#' @noRd
md_to_html <- function(x) {

  non_na_x <-
    x[!is.na(x)] %>%
    as.character() %>%
    vapply(commonmark::markdown_html, character(1), USE.NAMES = FALSE) %>%
    tidy_gsub("^", "<div class='gt_from_md'>") %>%
    tidy_gsub("$", "</div>")

  x[!is.na(x)] <- non_na_x
  x
}

#' Transform Markdown text to LaTeX
#'
#' In addition to the Markdown-to-LaTeX text transformation,
#' `markdown_to_latex()` also escapes ASCII characters with special meaning in
#' LaTeX.
#' @importFrom commonmark markdown_latex
#' @noRd
markdown_to_latex <- function(text) {

  # Vectorize `commonmark::markdown_latex` and modify output
  # behavior to passthrough NAs
  lapply(text, function(x) {

    if (is.na(x)) {
      return(NA_character_)
    }

    if (isTRUE(getOption("gt.html_tag_check", TRUE))) {

      if (grepl("<[a-zA-Z\\/][^>]*>", x)) {
        warning("HTML tags found, and they will be removed.\n",
                " * set `options(gt.html_tag_check = FALSE)` to disable this check",
                call. = FALSE)
      }
    }

    commonmark::markdown_latex(x) %>% tidy_gsub("\\n$", "")
  }) %>%
    unlist() %>%
    unname()
}

#' Transform Markdown text to plain text
#'
#' @importFrom commonmark markdown_text
#' @noRd
markdown_to_text <- function(text) {

  # Vectorize `commonmark::markdown_text` and modify output
  # behavior to passthrough NAs
  lapply(text, function(x) {

    if (is.na(x)) {
      return(NA_character_)
    }

    if (isTRUE(getOption("gt.html_tag_check", TRUE))) {

      if (grepl("<[a-zA-Z\\/][^>]*>", x)) {
        warning("HTML tags found, and they will be removed.\n",
                " * set `options(gt.html_tag_check = FALSE)` to disable this check",
                call. = FALSE)
      }
    }

    commonmark::markdown_text(x) %>% tidy_gsub("\\n$", "")
  }) %>%
    unlist() %>%
    unname()
}

#' Handle formatting of a pattern in a \code{fmt_*()} function
#'
#' Within the context of a \code{fmt_*()} function, we always have the
#' single-length character vector of \code{pattern} available to describe a
#' final decoration of the formatted values. We use \pkg{glue}'s semantics here
#' and reserve \code{x} to be the formatted values, and, we can use \code{x}
#' multiple times in the pattern.
#' @param pattern A formatting pattern that allows for decoration of the
#'   formatted value (defined here as \code{x}).
#' @param values The values (as a character vector) that are formatted within
#'   the \code{fmt_*()} function.
#' @noRd
apply_pattern_fmt_x <- function(pattern,
                                values) {

  vapply(
    values,
    function(x) tidy_gsub(x = pattern, "{x}", x, fixed = TRUE),
    FUN.VALUE = character(1),
    USE.NAMES = FALSE
  )
}

#' Get a vector of indices for large-number suffixing
#'
#' @importFrom utils head
#' @noRd
non_na_index <- function(values,
                         index,
                         default_value = NA) {

  if (is.logical(index)) {
    index <- is.integer(index)
  }

  stopifnot(is.integer(index) || is.numeric(index))

  # The algorithm requires `-Inf` not being present
  stopifnot(!any(is.infinite(values) & values < 0))

  # Get a vector of suffixes, which may include
  # NA values
  res <- values[index]

  # If there are no NA values to reconcile, return
  # the index
  if (!any(is.na(res))) {
    return(index)
  }

  # Create a vector of positions (`seq_along(values)`),
  # but anywhere the `values` vector has an NA, use
  # `-Inf`; (it's important that `values` not have `-Inf`
  # as one of its elements)
  positions <- ifelse(!is.na(values), seq_along(values), -Inf)

  # Use rle (run-length encoding) to collapse multiple
  # instances of `-Inf` into single instances. This
  # makes it easy for us to replace them with their
  # nearest (lower) neighbor in a single step, instead of
  # having to iterate; for some reason, `rle()` doesn't
  # know how to encode NAs, so that's why we use -Inf
  # (seems like a bug)
  encoded <- rle(positions)

  # Replace each -Inf with its closest neighbor; basically,
  # we do this by shifting a copy of the values to the
  # right, and then using the original vector of (run-length
  # encoded) values as a mask over it
  encoded$values <-
    ifelse(
      encoded$values == -Inf,
      c(default_value, head(encoded$values, -1)),
      encoded$values
    )

  # Now convert back from run-length encoded
  positions <- inverse.rle(encoded)

  # positions[index] gives you the new index
  positions[index]
}

#' Get a tibble of scaling values and suffixes
#'
#' The `num_suffix()` function operates on a vector of numerical values and
#' returns a tibble where each row represents a scaled value for `x` and the
#' correct suffix to use during `x`'s character-based formatting
#' @importFrom dplyr tibble
#' @noRd
num_suffix <- function(x,
                       suffixes = c("K", "M", "B", "T"),
                       base = 1000,
                       scale_by) {

  # If `suffixes` is a zero-length vector, we
  # provide a tibble that will ultimately not
  # scale value or apply any suffixes
  if (length(suffixes) == 0) {

    return(
      dplyr::tibble(
        scale_by = rep_len(scale_by, length(x)),
        suffix = rep_len("", length(x))
      )
    )
  }

  # Obtain a vector of index values that places
  # each value of `x` (either postive or negative)
  # in the correct scale category, according to
  # the base value (defaulting to 1000); this works
  # in tandem with the `suffixes` vector, where each
  # index position (starting from 1) represents the
  # index here
  i <- floor(log(abs(x), base = base))
  i <- pmin(i, length(suffixes))

  # Replace any -Inf, Inf, or zero values
  # with NA (required for the `non_na_index()`
  # function)
  i[is.infinite(i) | i == 0] <- NA_integer_

  # Using the `non_na_index()` function on the
  # vector of index values (`i`) is required
  # to enable inheritance of scalars/suffixes
  # to ranges where the user prefers the last
  # suffix given (e.g, [K, M, `NA`, T] -->
  # [K, M, M, T])
  suffix_index <-
    non_na_index(
      values = suffixes,
      index = i,
      default_value = 0
    )

  # Replace any zero values in `suffix_index`
  # with NA values
  suffix_index[suffix_index == 0] <- NA_integer_

  # Get a vector of suffix labels; this vector
  # is to be applied to the scaled values
  suffix_labels <- suffixes[suffix_index]

  # Replace any NAs in `suffix_labels` with an
  # empty string
  suffix_labels[is.na(suffix_labels)] <- ""

  # Replace any NAs in `suffix_index` with zeros
  suffix_index[is.na(suffix_index)] <- 0

  # Create and return a tibble with `scale_by`
  # and `suffix` values
  dplyr::tibble(
    scale_by = 1 / base^suffix_index,
    suffix = suffix_labels
  )
}

#' An `isFALSE`-based helper function
#'
#' The `is_false()` function is similar to the `isFALSE()` function that was
#' introduced in R 3.5.0 except that this implementation works with earlier
#' versions of R.
#' @param x The single value to test for whether it is `FALSE`.
#' @noRd
is_false = function(x) {

  is.logical(x) && length(x) == 1L && !is.na(x) && !x
}

#' Normalize all suffixing input values
#'
#' This function normalizes the `suffixing` input to a character vector which is
#' later appended to scaled numerical values; the input can either be a single
#' logical value or a character vector
#' @param suffixing,scale_by The `suffixing` and `scale_by` options in some
#'   `fmt_*()` functions.
#' @noRd
normalize_suffixing_inputs <- function(suffixing,
                                       scale_by) {

  if (is_false(suffixing)) {

    # If `suffixing` is FALSE, then return `NULL`;
    # this will be used to signal there is nothing
    # to be done in terms of scaling/suffixing
    return(NULL)

  } else if (isTRUE(suffixing)) {

    # Issue a warning if `scale_by` is not 1.0 (the default)
    warn_on_scale_by_input(scale_by)

    # If `suffixing` is TRUE, return the default
    # set of suffixes
    return(c("K", "M", "B", "T"))

  } else if (is.character(suffixing)) {

    # Issue a warning if `scale_by` is not 1.0 (the default)
    warn_on_scale_by_input(scale_by)

    # In the case that a character vector is provided
    # to `suffixing`, we first want to check if there
    # are any names provided
    # TODO: found that the conditional below seems
    # better than other solutions to determine whether
    # the vector is even partially named
    if (!is.null(names(suffixing))) {
      stop("The character vector supplied to `suffixed` cannot contain names.",
           call. = FALSE)
    }

    # We can now return the character vector, having
    # adequately tested for improper cases
    return(suffixing)

  } else {

    # Stop function if the input to `suffixing` isn't
    # valid (i.e., isn't logical and isn't a valid
    # character vector)
    stop("The value provided to `suffixing` must either be:\n",
         " * `TRUE` or `FALSE` (the default)\n",
         " * a character vector with suffixing labels",
         call. = FALSE)
  }
}

#' If performing large-number suffixing, warn on `scale_by` != 1
#'
#' @param scale_by The `scale_by` option in some `fmt_*()` functions.
#' @noRd
warn_on_scale_by_input <- function(scale_by) {

  if (scale_by != 1) {
    warning("The value for `scale_by` cannot be changed if `suffixing` is ",
            "anything other than `FALSE`. The value provided to `scale_by` ",
            "will be ignored.",
            call. = FALSE)
  }
}

#' Derive a label based on a formula or a function name
#'
#' @import rlang
#' @noRd
derive_summary_label <- function(fn) {

  if (inherits(fn, "formula")) {

    (fn %>% rlang::f_rhs())[[1]] %>%
      as.character()

  } else {
    fn %>% as.character()
  }
}

#nocov start
#' A `system.file()` replacement specific to this package
#'
#' This is a conveient wrapper for `system.file()` where the `package` refers to
#' this package.
#' @noRd
system_file <- function(file) {
  system.file(file, package = "gt")
}
#nocov end

#' Remove all HTML tags from input text
#'
#' @noRd
remove_html <- function(text) {
  gsub("<.+?>", "", text)
}

#' Transform a CSS stylesheet to a tibble representation
#'
#' @importFrom dplyr bind_rows tibble filter mutate case_when select pull
#' @importFrom stringr str_remove str_extract str_trim str_detect
#' @noRd
get_css_tbl <- function(data) {

  raw_css_vec <-
    compile_scss(data) %>%
    as.character() %>%
    strsplit("\n") %>%
    unlist()

  ruleset_start <- which(grepl("\\{\\s*", raw_css_vec))
  ruleset_end <- which(grepl("\\s*\\}\\s*", raw_css_vec))

  css_tbl <- dplyr::tibble()

  for (i in seq(ruleset_start)) {

    css_tbl <-
      dplyr::bind_rows(
        css_tbl,
        dplyr::tibble(
          selector = rep(
            stringr::str_remove(raw_css_vec[ruleset_start[i]], "\\s*\\{\\s*$"),
            (ruleset_end[i] - ruleset_start[i] - 1)),
          property = raw_css_vec[(ruleset_start[i] + 1):(ruleset_end[i] - 1)] %>%
            stringr::str_extract("[a-zA-z-]*?(?=:)") %>%
            stringr::str_trim(),
          value = raw_css_vec[(ruleset_start[i] + 1):(ruleset_end[i] - 1)] %>%
            stringr::str_extract("(?<=:).*") %>%
            stringr::str_remove(pattern = ";\\s*") %>%
            stringr::str_remove(pattern = "\\/\\*.*") %>%
            stringr::str_trim()) %>%
          dplyr::filter(!is.na(property))
      )
  }

  # Add a column that has the selector type for each row
  # For anything other than a class selector, the class type
  # will entered as NA
  css_tbl <-
    css_tbl %>%
    dplyr::mutate(type = dplyr::case_when(
      stringr::str_detect(selector, "^\\.") ~ "class",
      !stringr::str_detect(selector, "^\\.") ~ NA_character_)) %>%
    dplyr::select(selector, type, property, value)

  # Stop function if any NA values found while inspecting the
  # selector names (e.g., not determined to be class selectors)
  if (any(is.na(css_tbl %>% dplyr::pull(type)))) {
    stop("All selectors must be class selectors", call. = FALSE)
  }

  css_tbl
}

#' Create an inlined style block from a CSS tibble
#'
#' @importFrom dplyr filter select distinct mutate pull
#' @importFrom stringr str_split
#' @noRd
create_inline_styles <- function(class_names,
                                 css_tbl,
                                 extra_style = "") {

  class_names <-
    class_names %>%
    stringr::str_split("\\s+") %>%
    unlist()

  paste0(
    "style=\"",
    css_tbl %>%
      dplyr::filter(selector %in% paste0(".", class_names)) %>%
      dplyr::select(property, value) %>%
      dplyr::distinct() %>%
      dplyr::mutate(property_value = paste0(property, ":", value, ";")) %>%
      dplyr::pull(property_value) %>%
      paste(collapse = ""),
    extra_style,
    "\"")
}

#' Transform HTML to inlined HTML using a CSS tibble
#'
#' @importFrom stringr str_extract str_replace str_match
#' @noRd
inline_html_styles <- function(html, css_tbl) {

  cls_sty_pattern <- "class=\\'(.*?)\\'\\s+style=\\\"(.*?)\\\""

  repeat {

    matching_css_style <-
      html %>%
      stringr::str_extract(
        pattern = cls_sty_pattern)

    if (is.na(matching_css_style)) {
      break
    }

    class_names <-
      matching_css_style %>%
      stringr::str_extract("(?<=\\').*(?=\\')")

    existing_style <-
      matching_css_style %>%
      stringr::str_match(
        pattern = "style=\\\"(.*?)\\\"") %>%
      magrittr::extract(1, 2)

    inline_styles <-
      create_inline_styles(
        class_names = class_names, css_tbl, extra_style = existing_style)

    html <-
      html %>%
      stringr::str_replace(
        pattern = cls_sty_pattern,
        replacement = inline_styles)
  }

  cls_pattern <- "class=\\'(.*?)\\'"

  repeat {

    class_names <-
      html %>%
      stringr::str_extract(
        pattern = cls_pattern) %>%
      stringr::str_extract("(?<=\\').*(?=\\')")

    if (is.na(class_names)) {
      break
    }

    inline_styles <-
      create_inline_styles(
        class_names = class_names, css_tbl)

    html <-
      html %>%
      stringr::str_replace(
        pattern = cls_pattern,
        replacement = inline_styles)
  }

  html
}

#' Split any strings that are values in scientific notation
#'
#' @param x_str The input character vector of values formatted in scientific
#'   notation.
#' @noRd
split_scientific_notn <- function(x_str) {

  exp_parts <- strsplit(x_str, "e|E")
  num_part <- exp_parts %>% vapply(`[[`, character(1), 1)
  exp_part <- exp_parts %>% vapply(`[[`, character(1), 2) %>% as.numeric()

  list(num = num_part, exp = exp_part)
}

#' Wrapper for `gsub()` where `x` is the first argument
#'
#' This function is wrapper for `gsub()` that uses default argument values and
#' rearranges first three arguments for better pipelining
#' @param x,pattern,replacement,fixed Select arguments from the `gsub()`
#'   function.
#' @noRd
tidy_gsub <- function(x, pattern, replacement, fixed = FALSE) {

  gsub(pattern, replacement, x, fixed = fixed)
}

#' An options setter for the `opts_df` data frame
#'
#' @param opts_df The `opts_df` data frame.
#' @param option The option name; a unique value in the `parameter` column of
#'   `opts_df`.
#' @param value The value to set for the given `option`.
#' @noRd
opts_df_set <- function(opts_df, option, value) {

  opts_df[which(opts_df$parameter == option), "value"] <- value

  opts_df
}

#' An options getter for the `opts_df` data frame
#'
#' @inheritParams opts_df_set
#' @noRd
opts_df_get <- function(opts_df, option) {

  opts_df[which(opts_df$parameter == option), "value"]
}

#' Upgrader function for `cells_*` objects
#'
#' Upgrade a `cells_*` object to a `list()` if only a single instance is
#' provided.
#' @param locations Any `cells_*` object.
#' @noRd
as_locations <- function(locations) {

  if (!inherits(locations, "location_cells")) {

    if (!is.list(locations) &&
        any(!vapply(locations, inherits, logical(1), "location_cells"))) {

      stop("The `locations` object should be a list of `cells_*()`.",
           .call = FALSE)
    }
  } else {
    locations <- list(locations)
  }

  locations
}

#' Create a vector of glyphs to use for footnotes
#'
#' @noRd
footnote_glyphs <- function(x,
                            glyphs) {

  glyphs <- strsplit(glyphs, ",") %>% unlist()

  if (identical(glyphs, "numbers")) {
    return(as.character(x))
  }

  if (identical(glyphs, "LETTERS")) {
    glyphs <- LETTERS
  }

  if (identical(glyphs, "letters")) {
    glyphs <- letters
  }

  glyphs_rep <- floor((x - 1) / length(glyphs)) + 1

  glyphs_val <- glyphs[(x - 1) %% length(glyphs) + 1]

  mapply(
    glyphs_val, glyphs_rep,
    FUN = function(val_i, rep_i) {
      paste(rep(val_i, rep_i), collapse = "")}
  ) %>%
    unname()
}

#' Determine whether an object is a `gt_tbl`
#'
#' @param data A table object that is created using the \code{\link{gt}()}
#'   function.
#' @importFrom checkmate test_class
#' @noRd
is_gt <- function(data) {

  checkmate::test_class(data, "gt_tbl")
}

#' Stop any function if object is not a `gt_tbl` object
#'
#' @param data A table object that is created using the \code{\link{gt}()}
#'   function.
#' @noRd
stop_if_not_gt <- function(data) {

  if (!is_gt(data)) {
    stop("The object to `data` is not a `gt_tbl` object.", call. = FALSE)
  }
}
