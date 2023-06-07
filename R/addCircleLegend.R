#' Add custom circle legend to leaflet map
#'
#' To be used alongside \link[leaflet]{addCircleMarkers}
#'
#' @param map a leaflet map
#' @param title title of the legend
#' @param values the values used to generate circle radii
#' @param scaling_fn the scaling function used with \link[leaflet]{addCircleMarkers} to scale circle radii appropriately for leaflet
#' @param ... additional arguements passed to scaling_fn
#' @param color stroke color
#' @param weight stroke width in pixels
#' @param fillColor fill color
#' @param fillOpacity fill opacity
#' @param position the position of the legend
#' @param layerId the ID of the legend; subsequent calls to \code{addLegend}
#'   or \code{addControl} with the same \code{layerId} will replace this
#'   legend. The ID can also be used with \code{removeControl}.
#' @param group group name of a leaflet layer group
#' @param className extra CSS class to append to the control, space separated
#' @param data a data object used for the leaflet map
#'
#' @return an object from \link[leaflet]{addControl}
#'
#' @export
addCircleLegend <- function(map,
                            title = "",
                            values,
                            scaling_fn,
                            ...,
                            color,
                            weight,
                            fillColor,
                            fillOpacity,
                            position = c("topright", "bottomright", "bottomleft", "topleft"),
                            className = "info legend leaflet-control",
                            layerId = NULL,
                            group = NULL,
                            data = leaflet::getMapData(map)) {
  # browser()
  values <- parseValues(values = values, data = data)
  rv <- range(values, na.rm = TRUE)
  if ((rv[2] - rv[1]) < 10) {
    brks <- rv
  } else {
    brks <- base::pretty(sort(values), 3)
  }
  # brks <- scales::breaks_pretty(values, 4)
  # min_n <- ceiling(min(range, na.rm = TRUE))
  # med_n <- round(median(range, na.rm = TRUE), 0)
  # max_n <- round(max(range, na.rm = TRUE), 0)
  # n_range <- c(min_n, med_n, max_n)
  n_range <- brks[brks != 0]
  radii <- scaling_fn(n_range, ...)
  n_range <- scales::number(n_range, scale_cut = scales::cut_short_scale(), accuracy = 0.1)
  n_range <- gsub("\\.0", "", n_range)
  n_pad <- max(nchar(n_range)) * 10 + 5

  circle_style <- glue::glue(
    "border-radius:50%;
    border: {weight}px solid {color};
    background: {paste0(fillColor, round(fillOpacity*100, 0))};
    position: absolute;
    bottom:1px;
    right:25%;
    left:50%;"
  )

  text_style <- glue::glue(
    "text-align: right;
    font-size: 9px;
    position: absolute;
    bottom: 0px;
    right:1px;"
  )

  get_leg_circle <- function(radius, circle_style) {
    glue::glue('<div class="legendCircle" style="width: {radius * 2}px; height: {radius * 2}px; margin-left: {-radius}px; {circle_style}"></div>')
  }

  get_leg_value <- function(radius, value, text_style) {
    glue::glue('<div><p class="legendValue" style="margin-bottom: {radius * 2 - 12}px; {text_style}">{value}</p></div>', )
  }

  divs_circles <- glue::glue_collapse(get_leg_circle(rev(radii), circle_style), sep = "\n")
  divs_values <- glue::glue_collapse(get_leg_value(rev(radii), rev(n_range), text_style), sep = "\n")
  max_radius <- max(radii)

  html <- htmltools::HTML(glue::glue(
    '<div>
    <div id="legendTitle" style="text-align: center; font-weight: bold;">{title}</div>
    <div class="symbolsContainer" style="min-width: {max_radius*2 + n_pad}px; min-height: {max_radius*2}px;">
    {divs_circles}
    {divs_values}
    </div>
    </div>'
  ))

  if ( !is.null(group) ) {
    leafLegendClassName <- paste('leaflegend-group', gsub('\\W', '', group), sep = '-')
    className <- paste(className, leafLegendClassName)

    lf <- leaflet::addControl(map, html = html, position = position, layerId = layerId, className = className)
    htmlwidgets::onRender(
      lf,
      "
      function(el, x) {
        var updateLeafLegend = function() {
          var controlGroups = document.querySelectorAll('input.leaflet-control-layers-selector');
          controlGroups.forEach(g => {
            var groupName = g.nextSibling.innerText.substr(1);
            var className = 'leaflegend-group-' + groupName.replace(/[^a-zA-Z0-9]/g, '');
            var checked = g.checked;
            document.querySelectorAll('.legend.' + className).forEach(l => {
              l.hidden = !checked;
            })
          })
        }
        updateLeafLegend();
        this.on('baselayerchange', el => updateLeafLegend())
        this.on('overlayadd', el => updateLeafLegend());
        this.on('overlayremove', el => updateLeafLegend());
      }
      ")
  } else {
    leaflet::addControl(map, html = html, position = position, layerId = layerId, className = className)
  }
}

parseValues <- function(values, data) {
  if ( inherits(values, 'formula') ) {
    stopifnot(!is.null(data))
    leaflet::evalFormula(values, data)
  } else {
    values
  }
}
