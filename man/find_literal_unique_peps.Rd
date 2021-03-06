% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/psmtable.R
\name{find_literal_unique_peps}
\alias{find_literal_unique_peps}
\title{Find peptides that are unique by protein entries}
\usage{
find_literal_unique_peps(df, pep_id = "pep_seq", prot_id = "prot_acc")
}
\arguments{
\item{df}{PSM data.}

\item{pep_id}{the column key of peptide sequences.}

\item{prot_id}{The column key of protein accessions.}
}
\description{
Find peptides that are unique by protein entries
}
