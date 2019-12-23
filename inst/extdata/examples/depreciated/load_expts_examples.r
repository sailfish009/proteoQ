# ===================================
# Fasta and PSM files
# ===================================
# fasta (all platforms)
library(proteoQDA)
fasta_dir <- "~\\proteoQ\\dbs\\fasta\\refseq"
dir.create(fasta_dir, recursive = TRUE, showWarnings = FALSE)
copy_refseq_hs(fasta_dir)
copy_refseq_mm(fasta_dir)

# working directory (all platforms)
dat_dir <- "~\\proteoQ\\examples"
dir.create(dat_dir, recursive = TRUE, showWarnings = FALSE)

# metadata (all platforms)
copy_global_exptsmry(dat_dir)
cptac_global_fracsmry(dat_dir)

# PSM (choose one of the platforms)
choose_one <- TRUE
if (!choose_one) {
  # Mascot
  copy_global_mascot(dat_dir)
  
  # or MaxQuant
  copy_global_maxquant(dat_dir)
  
  # or Spectrum Mill
  copy_global_sm(dat_dir)
}


# ===================================
# PSM, peptide and protein processing
# ===================================
library(proteoQ)
dat_dir <- "~\\proteoQ\\examples"
load_expts()

# PSM data standardization
normPSM(
  fasta = c("~\\proteoQ\\dbs\\fasta\\refseq\\refseq_hs_2013_07.fasta",
            "~\\proteoQ\\dbs\\fasta\\refseq\\refseq_mm_2013_07.fasta"),
)

# optional PSM purging
purgePSM()

# PSMs to peptides
PSM2Pep()

# peptide data merging
mergePep()

# peptide data standardization
standPep()

# optional peptide purging
purgePep(pt_cv = .95)

# peptides to proteins
Pep2Prn(use_unique_pep = TRUE)

# protein data standardization
standPrn()

