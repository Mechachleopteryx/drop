#'---
#' title: Aberrant Expression
#' author:
#' wb:
#'  log:
#'    - snakemake: '`sm str(tmp_dir / "AE" / "Overview.Rds")`'
#'  params:
#'    - annotations: '`sm cfg.getGeneVersions()`'
#'    - datasets: '`sm cfg.AE.groups`'
#'    - htmlDir: '`sm config["htmlOutputPath"] + "/AberrantExpression"`'
#'  input:
#'    - odsFiles: '`sm expand(cfg.getProcessedResultsDir() +
#'                  "/aberrant_expression/{annotation}/outrider/{dataset}/ods.Rds",
#'                  annotation=cfg.getGeneVersions(), dataset=cfg.AE.groups)`'
#'    - resultTables: '`sm expand(cfg.getProcessedResultsDir() +
#'                      "/aberrant_expression/{annotation}/outrider/" +
#'                      "{dataset}/OUTRIDER_results.tsv",
#'                      annotation=cfg.getGeneVersions(), dataset=cfg.AE.groups)`'
#' output:
#'   html_document:
#'    code_folding: show
#'    code_download: TRUE
#'---

#+ echo=F
saveRDS(snakemake, snakemake@log$snakemake)

suppressPackageStartupMessages({
  library(OUTRIDER)
})

# define functions
get_html_path <- function(annotationVersion, datasets, htmlDir, fileName) {
  file_paths <- file.path(htmlDir, annotationVersion, fileName)
  file_link <- paste0('\n* [', datasets ,'](', file_paths, 
                      '){target="_blank"}\n', collapse = ' ')
  file_link
}

display_text <- function(caption, links) {
  paste0('**', caption, '**', names(links), '\n', links, collapse = '\n')
}

# get parameters
datasets <- sort(snakemake@params$datasets)
annotations <- snakemake@params$annotations
htmlDir <- snakemake@params$htmlDir

## start html

#'
#' **Datasets:** `r paste(datasets, collapse = ', ')`
#' 
#' **Gene annotations:** `r paste(annotations, collapse = ', ')`
#'
#' ## Summaries
#' ### Counts summary
#+ echo=FALSE
htmlDir <- './AberrantExpression'
count_links <- sapply(annotations, get_html_path, 
                      datasets = datasets,
                      htmlDir = file.path(htmlDir, "Counting"), 
                      fileName = paste0('Summary_', datasets, '.html'))
#' 
#' `r display_text(caption = 'Gene annotation version ', count_links)`
#' 
#' ### OUTRIDER summary
#+ echo=FALSE
outrider_links <- sapply(annotations, get_html_path, 
                         datasets = datasets,
                         htmlDir = file.path(htmlDir, "Outrider"), 
                         fileName = paste0('Summary_', datasets, '.html'))
#' 
#' `r display_text(caption = 'Gene annotation version ', outrider_links)`
#' 
#' ## Files
#' ### OUTRIDER datasets (ods)
#' 
#' `r paste('* ', snakemake@input$odsFiles, collapse = '\n')`
#' 
#' ### Results tables
#' 
#'  `r paste('* ', snakemake@input$resultTables, collapse = '\n')`
#' 

#' ## Analyze Individual Results
# Read the first ods object and results table
ods <- readRDS(snakemake@input$odsFiles[[1]])
res <- fread(snakemake@input$resultTables[[1]])

#' Display the results table of the first dataset
#+ echo=FALSE
DT::datatable(res, filter = 'top')

#' Choose a random gene and sample to plot. Outliers are in red.
#+ echo=TRUE
gene <- res[1, geneID]
sample <- res[1, sampleID]

#' ### Volcano plot
#' setting basePlot = FALSE creates an interactive plot
#' that allows finding the gene(s) of interest
OUTRIDER::plotVolcano(ods, sample, basePlot = TRUE)

#' ### Gene expression plot (normalized counts)
OUTRIDER::plotExpressionRank(ods, gene, basePlot = TRUE)

#' ### Expected vs observed counts
OUTRIDER::plotExpectedVsObservedCounts(ods, gene, basePlot = TRUE)

