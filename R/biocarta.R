
#' All BioCarta pathways
#' 
#' @return A vector of pathway IDs.
#' @export
#' @examples
#' all_pathways()
all_pathways = function() {
	names(BIOCARTA_PATHWAYS)
}

#' Get a single pathway
#' 
#' @param pathway_id A biocarta pathway ID.
#' 
#' @return A `biocarta_pathway` object.
#' @export
#' @examples
#' get_pathway("h_RELAPathway")
get_pathway = function(pathway_id) {

	pathway_id = match_pathway_id(pathway_id)

	BIOCARTA_PATHWAYS[[pathway_id]]

}

match_pathway_id = function(pathway_id) {
	ap = all_pathways()
	ap2 = tolower(ap)
	ap2 = gsub("^\\w_", "", ap2)
	i = which(ap2 == gsub("^\\w_", "", tolower(pathway_id)))

	if(length(i) == 0) {
		stop("Cannot find pathway:", pathway_id)
	}

	ap[i]
}

#' Print the biocarta_pathway object
#' 
#' @param x A `biocarta_pathway` object.
#' @param ... Other arguments
#' 
#' @exportS3Method print biocarta_pathway
#' @return Nothing.
#' @examples
#' p = get_pathway("h_RELAPathway")
#' p
print.biocarta_pathway = function(x, ...) {
	cat("A BioCarta pathway:\n")
	cat("  ID: ", x$id, "\n", sep = "")
	cat("  Name: ", x$name, "\n", sep = "")
	cat("  ", length(x$genes), " nodes, ", length(unique(BC2ENTREZ$ENTREZ[BC2ENTREZ$BCID %in% x$genes])), " genes", "\n", sep = "")
}

#' Genes in a pathway
#' 
#' @param pathway A pathway ID or a `biocarta_pathway` object.
#' 
#' @return A character vector of Entrez IDs.
#' @export
#' @examples
#' genes_in_pathway("h_RELAPathway")
genes_in_pathway = function(pathway) {
	if(inherits(pathway, "character")) {
		pathway = get_pathway(pathway)
	}
	unique(BC2ENTREZ$ENTREZ[BC2ENTREZ$BCID %in% pathway$genes])
}


entrez_to_BC = function(entrez_id) {
	BC2ENTREZ$BCID[ BC2ENTREZ$ENTREZ %in% entrez_id ]
}

BC_to_entrez = function(bc_id) {
	BC2ENTREZ$ENTREZ[ BC2ENTREZ$BCID %in% bc_id ]
}

.ENV = new.env()
.ENV$image = list()

IMAGE_BASE_URL = "https://jokergoo.github.io/BioCartaImage/image/"

#' Download the pathway image
#' 
#' @param pathway A pathway ID or a `biocarta_pathway` object.
#' 
#' @return A `raster` object.
#' @export
#' @importFrom magick image_read
#' @importFrom grDevices as.raster
#' @examples
#' img = get_pathway_image("h_RELAPathway")
#' class(img)
#' 
#' image_dimension("h_RELAPathway")
get_pathway_image = function(pathway) {

	if(inherits(pathway, "character")) {
		pathway = get_pathway(pathway)
	}

	pathway_id = pathway$id

	if(is.null(.ENV$image[[pathway_id]])) {
		url = paste0(IMAGE_BASE_URL, "/", pathway$image_file)
		img = image_read(url)
		.ENV$image[[pathway_id]] = as.raster(img)
	}
	.ENV$image[[pathway_id]]
}

#' @rdname get_pathway_image
#' @export
image_dimension = function(pathway) {
	image = get_pathway_image(pathway)
	dim(image)
}

#' Draw a BioCarta pathway
#' 
#' @param pathway A pathway ID or a `biocarta_pathway` object.
#' @param color A named vector where names should correspond to Entrez IDs.
#' @param x A numeric vector or unit object specifying x-location.
#' @param y A numeric vector or unit object specifying y-location.
#' @param width A numeric vector or unit object specifying width.
#' @param height A numeric vector or unit object specifying width.
#' @param just The same as in [`grid::viewport()`].
#' @param default.units The same as in [`grid::viewport()`].
#' @param name The same as in [`grid::viewport()`].
#' 
#' @details
#' The graphics object contains a pathway image and genes highlighted on the image.
#' 
#' The aspect ratio of the image is kept. If one of `width` and `height` is set, the
#' other dimension is calculated by the aspect ratio. If both of `width` and `height`
#' is set or inherit from parent viewport, the width and height are automatically adjust
#' to let one dimension completely fill the viewport.
#' 
#' @return `pathwayGrob()` returns a `gTree` object.
#' 
#' @export
#' @rdname pathwayGrob
#' @examples
#' library(grid)
#' grid.newpage()
#' grid.pathway("h_RELAPathway")
#' 
#' grob = pathwayGrob("h_RELAPathway")
grid.pathway = function(pathway, color = NULL, 
	x = unit(0.5, "npc"), y = unit(0.5, "npc"), 
	width = NULL, height = NULL, just = "centre", 
	default.units = "npc", name = NULL) {

	g = pathwayGrob(pathway = pathway, color = color, x = x, y = y,
		width = width, height = height, just = just,
		default.units = default.units, name = name)
	grid.draw(g)
}

#' @rdname pathwayGrob
#' @export
#' @import grid
pathwayGrob = function(pathway, color = NULL, 
	x = unit(0.5, "npc"), y = unit(0.5, "npc"), 
	width = NULL, height = NULL, just = "centre", 
	default.units = "npc", name = NULL) {

	if(inherits(pathway, "character")) {	
		pathway = get_pathway(pathway)
	}

	image = get_pathway_image(pathway$id)

	size = dim(image)
	image_height = size[1]
	image_width = size[2]

	shape = pathway$shape
	coords = pathway$coords

	vp = viewport(xscale = c(0, image_width), yscale = c(0, image_height),
		x = x, y = y, default.units = default.units, 
		just = just, name = name)
	vp$check_size = FALSE
	if(!is.null(width) && is.null(height)) {
		vp$width = width
		vp$height = image_height/image_width * vp$width
	} else if(is.null(width) && !is.null(height)) {
		vp$width = image_width/image_height * height
		vp$height = height
	} else if(!is.null(width) && !is.null(height)) {
		vp$width = width
		vp$height = height
		vp$check_size = TRUE
		vp$original_width = vp$width
		vp$original_height = vp$height
	} else {
		vp$check_size = TRUE
		vp$original_width = vp$width
		vp$original_height = vp$height
	}
	vp$pathway_id = pathway$id

	gl = gList(rasterGrob(image))

	n = length(shape)

	gl2 = list()

	genes = unique(pathway$genes)
	color2 = NULL
	if(!is.null(color)) {
		for(nm in names(color)) {
			if(nm %in% genes) {
				color2[[nm]] = color[[nm]]
			}
			# if the name is entrez
			bc = entrez_to_BC(nm)
			if(length(bc)) {
				color2[bc] = color[[nm]]
			}
		}
	}
	if(length(color2) == 0) color2 = NA

	genes = pathway$genes
	
	for(i in seq_len(n)) {
		x = coords[[i]]
		nx = length(x)

		if(!is.na(color2[ genes[i] ])) {
			if(shape[i] == "poly") {
				gl2[[i]] = polygonGrob(x[seq_len(nx/2)*2-1], image_height - x[seq_len(nx/2)*2], 
					default.units = "native", gp = gpar(col = color2[ genes[i] ], fill = NA, lwd = 2, lty = 3))
			} else if(shape[i] == "rect") {
				gl2[[i]] = rectGrob(x[1], height - x[2], width = x[3] - x[1], height = x[4] - x[2], 
					default.units = "native", just = c("left", "bottom"), gp = gpar(col = color2[ genes[i] ], fill = NA, lwd = 2, lty = 3))
			} else if(shape[i] == "circle") {
				gl2[[i]] = circleGrob(x[1], x[2], r = x[3], default.units = "native", gp = gpar(col = color2[ genes[i] ], fill = NA, lwd = 2, lty = 3))
			}
		}
	}

	gl = c(gl, gl2)
	class(gl) = "gList"

	gTree(children = gl, vp = vp, cl = "biocarta_pathway_grob")
}

#' Internal functions for drawing the pathway grob
#' 
#' @param x A `grob` returned by [`pathwayGrob()`].
#' 
#' @exportS3Method makeContext biocarta_pathway_grob
#' @return A `grob` object.
#' @rdname internal
makeContext.biocarta_pathway_grob = function(x) {

	if(x$vp$check_size) {

		width = x$vp$xscale[2]
		height = x$vp$yscale[2]

		vp_w = convertWidth(x$vp$original_width, "in", valueOnly = TRUE)
		vp_h = convertHeight(x$vp$original_height, "in", valueOnly = TRUE)

		if(vp_w/vp_h > width/height) {
			x$vp$width = unit(width/height*vp_h, "in")
			x$vp$height = unit(vp_h, "in")
		} else {
			x$vp$width = unit(vp_w, "in")
			x$vp$height = unit(height/width*vp_w, "in")
		}
	}

	x
}

#' @exportS3Method grobWidth biocarta_pathway_grob
#' @return A `unit` object.
#' @rdname internal
grobWidth.biocarta_pathway_grob = function(x) {
	if(x$vp$check_size) {

		width = x$vp$xscale[2]
		height = x$vp$yscale[2]

		vp_w = convertWidth(x$vp$original_width, "in", valueOnly = TRUE)
		vp_h = convertHeight(x$vp$original_height, "in", valueOnly = TRUE)

		if(vp_w/vp_h > width/height) {
			x$vp$width = unit(width/height*vp_h, "in")
			x$vp$height = unit(vp_h, "in")
		} else {
			x$vp$width = unit(vp_w, "in")
			x$vp$height = unit(height/width*vp_w, "in")
		}
	}
	x$vp$width
}

#' @exportS3Method grobHeight biocarta_pathway_grob
#' @return A `unit` object.
#' @rdname internal
grobHeight.biocarta_pathway_grob = function(x) {
	if(x$vp$check_size) {

		width = x$vp$xscale[2]
		height = x$vp$yscale[2]

		vp_w = convertWidth(x$vp$original_width, "in", valueOnly = TRUE)
		vp_h = convertHeight(x$vp$original_height, "in", valueOnly = TRUE)

		if(vp_w/vp_h > width/height) {
			x$vp$width = unit(width/height*vp_h, "in")
			x$vp$height = unit(vp_h, "in")
		} else {
			x$vp$width = unit(vp_w, "in")
			x$vp$height = unit(height/width*vp_w, "in")
		}
	}
	x$vp$height
}

# approximate
#' @importFrom stats dist
polygon_area = function(x, y) {

	if(missing(y)) {
		y = x[[2]]
		x = x[[1]]
	}

	diameter = max(dist(cbind(x, y)))
	# as a circle
	a1 = pi*(diameter/2)^2

	# as a rectanger
	w = max(x) - min(x)
	h = max(y) - min(y)
	a2 = w*h	

	min(a1, a2)
}

#' Mark a gene on the pathway image
#' 
#' @param grob A `grob` returned by [`pathwayGrob()`].
#' @param entrez_id A single Entrez ID.
#' @param fun A self-defined function to add graphics to the selected gene.
#' @param min_area Multiple polygons may be used for one single gene in the image. It can be used
#'         to select the largest polygon. The unit for calculating the area is the pixel in the image.
#' @param capture It is suggested `fun()` to directly return `grob` objects. But you can also directly
#'         use functions such as `grid.points()` or `grid.lines()`. In this case, `capture` must be set
#'         to `TRUE` to capture these `grob`s.
#' 
#' @details
#' `fun()` should be applied to each gene. It is possible an Entrez gene is mapped to multiple nodes
#' in the image, so more precisely, `fun()` is applied to every node that contains the input gene.
#' 
#' `fun()` only accepts two arguments, `x` and `y` which are two vectors of xy-coordinates that define
#' the polygon. The helper function [`pos_by_polygon()`] can be used to get positions around the polygon.
#' 
#' There are two ways to use `fun()`. First, `fun()` directly returns a `grob`. It can be a simple grob, such
#' as by [`grid::pointsGrob()`] or complicate grob by [`grid::gTree()`] and [`grid::gList()]`. Second, `fun()`
#' can directly include plotting functions such as [`grid::grid.points()`], in this case, `capture` argument
#' must be set to `TRUE` to capture these grobs.
#' 
#' @return A grob where new graphics are added.
#' @export
#' @examples
#' library(grid)
#' grid.newpage()
#' grob = pathwayGrob("h_RELAPathway")
#' # gene 1387 is a gene in the pathway
#' grob2 = mark_gene(grob, "1387", function(x, y) {
#' 	pos = pos_by_polygon(x, y)
#' 	pointsGrob(pos[1], pos[2], default.units = "native", pch = 16, 
#' 		gp = gpar(col = "red"))
#' })
#' grid.draw(grob2)
#'
#' grid.newpage()
#' grob3 = mark_gene(grob, "1387", function(x, y) {
#' 	pos = pos_by_polygon(x, y)
#' 	grid.points(pos[1], pos[2], default.units = "native", pch = 16,
#' 		gp = gpar(col = "red"))
#' }, capture = TRUE)
#' grid.draw(grob3)
#' 
#' grid.newpage()
#' grob4 = mark_gene(grob, "1387", function(x, y) {
#' 	pos = pos_by_polygon(x, y)
#' 	pushViewport(viewport(x = pos[1], y = pos[2], 
#' 		width = unit(4, "cm"), height = unit(4, "cm"), 
#' 		default.units = "native", just = "right"))
#' 	grid.rect(gp = gpar(fill = "white"))
#' 	popViewport()
#' }, capture = TRUE)
#' grid.draw(grob4)
mark_gene = function(grob, entrez_id, fun, min_area = 0, capture = FALSE) {
	pathway = get_pathway(grob$vp$pathway_id)

	entrez_id = as.character(entrez_id)
	bc = entrez_to_BC(entrez_id)

	ind = which(pathway$genes %in% bc)

	for(i in ind) {
		xy = coords_to_xy(pathway$coords[[i]], pathway$shape[i])
		xy$y = grob$vp$yscale[2] - xy$y

		if(min_area > 0) {
			if(polygon_area(xy) < min_area) {
				next
			}
		}

		if(capture) {
			g = grid.grabExpr(fun(xy$x, xy$y))
		} else {
			g = fun(xy$x, xy$y)
		}

		if(!inherits(g, "grob")) {
			stop("`fun()` should return a grob object.")
		}

		grob$children[[ g$name ]] = g
		grob$childrenOrder = c(grob$childrenOrder, g$name)
	}

	grob
}



coords_to_xy = function(coords, shape) {
	n = length(coords)
	if(shape == "poly") {
		list(x = coords[seq_len(n/2)*2-1],
			 y = coords[seq_len(n/2)*2])
	} else if(shape == "rect") {
		list(x = c(coords[1], coords[1], coords[3], coords[3], coords[1]),
			 y = c(coords[2], coords[2], coords[4], coords[4], coords[2]))
	} else {
		list(x = coords[1] + coords[3]*cos(seq(0, 2*pi, 20)),
			 y = coords[2] + coords[3]*sin(seq(0, 2*pi, 20)))
	}
}

#' Position around a polygon
#' 
#' @param x x-coordinate of a polygon.
#' @param y y-coordinate of a polygon.
#' @param where Which side of the polygon. It should take value in `c("left", "right", "top", "bottom", "topleft", "topright", "bottomleft", "bottomright")`.
#' 
#' @return A numeric scalar of length two, which is the xy-coordinate of the point.
#' @export
#' @examples
#' x = c(235, 235, 237, 241, 246, 248, 250, 250, 250, 253,
#'       256, 260, 264, 263, 261, 257, 252, 247, 241, 237, 235)
#' y = c(418, 409, 402, 397, 394, 395, 396, 404, 411, 416, 417, 
#'       416, 415, 422, 429, 434, 437, 436, 432, 426, 418)
#' pos_by_polygon(x, y, "left")
#' pos_by_polygon(x, y, "bottomleft")
pos_by_polygon = function(x, y, where = "left") {
	if(!where %in% c("left", "right", "top", "bottom", "topleft", "topright", "bottomleft", "bottomright")) {
		stop('`where` should take value in c("left", "right", "top", "bottom", "topleft", "topright", "bottomleft", "bottomright").')
	}

	if(where == "left") {
		c(min(x), mean(y))
	} else if(where == "right") {
		c(max(x), mean(y))
	} else if(where == "top") {
		c(mean(x), max(y))
	} else if(where == "bottom") {
		c(mean(x), min(y))
	} else if(where == "topleft") {
		c(min(x), max(y))
	} else if(where == "topright") {
		c(max(x), max(y))
	} else if(where == "bottomleft") {
		c(min(x), min(y))
	} else if(where == "bottomright") {
		c(min(x), max(y))
	}
}