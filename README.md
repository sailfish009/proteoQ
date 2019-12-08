Package proteoQ
================
true
2019-12-07

  - [Introduction to proteoQ](#introduction-to-proteoq)
  - [Installation](#installation)
  - [1 Data normalization](#data-normalization)
      - [1.1 Set up experiment for Mascot
        workflow](#set-up-experiment-for-mascot-workflow)
      - [1.2 Summarise Mascot PSMs](#summarise-mascot-psms)
      - [1.3 Summarize PSMs to peptides](#summarize-psms-to-peptides)
      - [1.4 Summarize peptides to
        proteins](#summarize-peptides-to-proteins)
      - [1.5 scale\_log2\_r](#scale_log2_r)
      - [1.5 Summarize MaxQuant results](#summarize-maxquant-results)
      - [1.6 Summarize Spectrum Mill
        results](#summarize-spectrum-mill-results)
      - [1.7 Workflow scripts](#workflow-scripts)
  - [2 Basic informatics](#basic-informatics)
      - [2.1 MDS and PCA plots](#mds-and-pca-plots)
      - [2.2 Correlation plots](#correlation-plots)
      - [2.3 Heat maps](#heat-maps)
      - [2.4 Significance tests and volcano plot
        visualization](#significance-tests-and-volcano-plot-visualization)
      - [2.5 Gene sets under volcano
        plots](#gene-sets-under-volcano-plots)
      - [2.6 Gene set networks](#gene-set-networks)
      - [2.7 Trend Analysis](#trend-analysis)
      - [2.8 NMF Analysis](#nmf-analysis)
      - [2.9 STRING Analysis](#string-analysis)
      - [2.9 Missing value imputation](#missing-value-imputation)
  - [3 Labs](#labs)
      - [3.1 Reference choices](#reference-choices)
      - [3.2 Data subsets](#data-subsets)
      - [3.3 Random effects](#random-effects)
  - [4 Column keys](#column-keys)
      - [4.1 Mascot](#mascot)
      - [4.2 MaxQuant](#maxquant)
  - [References](#references)

<style>
p.comment {
background-color: #e5f5f9;
padding: 10px;
border: 1px solid black;
margin-left: 0px;
border-radius: 5px;
}

</style>

## Introduction to proteoQ

Chemical labeling using tandem mass tag
([TMT](https://en.wikipedia.org/wiki/Tandem_mass_tag)) has been commonly
applied in mass spectrometry (MS)-based quantification of proteins and
peptides. The `proteoQ` tool is designed for automated and reproducible
analysis of proteomics data. It interacts with an `Excel` spread sheet
for dynamic sample selections, aesthetics controls and statistical
modelings. It further integrates the utilities of data filtration and
ordering into functions at the users’ interface. The arrangements allow
users to put *ad hoc* manipulation of data behind the scene and instead
apply metadata to openly address biological questions using various
informatic tools. In addition, the entire workflow is documented and can
be conveniently reproduced upon revisiting.

The tool currently processes the peptide spectrum matches (PSM) tables
from [Mascot](https://http://www.matrixscience.com/),
[MaxQuant](https://www.maxquant.org/) and [Spectrum
Mill](https://www.agilent.com/en/products/software-informatics/masshunter-suite/masshunter-for-life-science-research/spectrum-mill)
searches, for 6-, 10- or 11-plex TMT experiments using Thermo’s orbitrap
mass analyzers. Peptide and protein results are then produced with
users’ selection of parameters in data filtration, alignment and
normalization. The package further offers a suite of tools and
functionalities in statistics, informatics and data visualization by
creating ‘wrappers’ around published R routines.

Click
<strong>[here](https://htmlpreview.github.io/?https://github.com/qzhang503/proteoQ/blob/master/README.html)</strong>
to render a html version of the README.

## Installation

To install this package, start R (version “3.6.1”) as **administrator**
and enter:

``` r
if (!requireNamespace("devtools", quietly = TRUE))
    install.packages("devtools")
devtools::install_github("qzhang503/proteoQ")
```

## 1 Data normalization

In this section I (Qiang Zhang) illustrate the following applications of
`proteoQ`:

  - Summarization of Mascot PSM results to normalized peptide and
    protein data.
  - Visualization of quality metrics in normalized peptide and protein
    data.
  - Re-normalization of data in partial or in full.
  - Removal of low-quality entries from PSM, peptide and protein data.
  - Summarization of MaxQuant PSM results.  
  - Summarization of Spectrum Mill PSM results.

The data set we will use in this section corresponds to the proteomics
data from Mertins et al. (2018). In the study, two different breast
cancer subtypes, triple negative (WHIM2) and luminal (WHIM16), from
patient-derived xenograft (PDX) models were assessed by three
independent laboratories. At each site, lysates from WHIM2 and WHIM16
were each split and labeled with 10-plex TMT at equal sample sizes and
repeated on a different day. This results in a total of 60 samples
labeled under six 10-plex TMT experiments. The samples under each
10-plex TMT were fractionated by off-line, high pH reversed-phase
(Hp-RP) chromatography, followed by `LC/MS` analysis. The raw PSM
results from [Mascot](https://http://www.matrixscience.com/) and
[Spectrum
Mill](https://www.agilent.com/en/products/software-informatics/masshunter-suite/masshunter-for-life-science-research/spectrum-mill)
are stored in a companion package, `proteoQDA`. The raw PSM results from
[MaxQuant](https://www.maxquant.org/) searches are stored in a second
companion package, `proteoQDB`.

### 1.1 Set up experiment for Mascot workflow

We first set up a working directory for use in a Mascot example:

``` r
dir.create("C:\\The\\Mascot\\Example", recursive = TRUE, showWarnings = FALSE)
dat_dir <- "C:\\The\\Mascot\\Example"
```

#### 1.1.1 Prepare fasta databases

RefSeq databases of human and mouse were used in the MS/MS searches
against the WHIM data sets. To properly annotate protein entries with
`proteoQ`, we would need the fasta file(s) that were used in the
database searches. In the example below, we copy over the corresponding
fasta files, which are available in `proteoQDA` package, to a file
folder sub to `home` directory:

``` r
devtools::install_github("qzhang503/proteoQDA")

library(proteoQDA)
copy_refseq_hs("~\\proteoQ\\dbs\\fasta\\refseq")
copy_refseq_mm("~\\proteoQ\\dbs\\fasta\\refseq")
```

#### 1.1.2 Prepare Mascot PSM data

The workflow begins with PSM table(s) in a `.csv` format from the
[Mascot](https://http://www.matrixscience.com/) search engine. When
exporting PSM results, I typically set the option of `Include sub-set
protein hits` to `0` with my opinionated choice in satisfying the
principle of parsimony. Under `Peptide Match Information`, the options
of `Header` and `Peptide quantitation` should be checked to include the
search parameters and quantitative values. The inclusion of both `Start`
and `End` is recommended and the file name(s) of the exports will be
taken as is.\[1\]

<img src="images\mascot\mascot_export.png" width="45%" style="display: block; margin: auto;" />

The same peptide sequence under different PSM files can be assigned to
different protein IDs when
[inferring](https://www.ncbi.nlm.nih.gov/m/pubmed/21447708/) proteins
from peptides using algorithms such as greedy set cover. To escape from
the ambiguity in protein inference, I typically enable the option of
`Merge MS/MS files into single search` in [Mascot
Daemon](http://www.matrixscience.com/daemon.html).\[2\] If the option is
disabled, peptide sequences that have been assigned to multiple protein
IDs will be removed for now when constructing peptide reports.

<img src="images\mascot\mascot_daemon.png" width="45%" style="display: block; margin: auto;" />

The merged search may become increasingly cumbersome with growing data
sets. In this example, I combined the MS peak lists from the Hp-RP
fractions within the same 10-plex TMT experiment, but not the lists
across experiments. This results in a total of six pieces of PSM results
in `Mascot` exports. To get us started, we go ahead and copy over the
PSM files that we have prepared in `proteoQDA` to the working directory:

``` r
cptac_csv_1(dat_dir)
```

#### 1.1.3 Prepare metadata

The workflow involves an `Excel` template containing the metadata of
multiplex experiments, including experiment numbers, TMT channels, LC/MS
injection indices, sample IDs, reference channels, `RAW` MS data file
names and additional fields from users. The default file name for the
experimental summary is `expt_smry.xlsx`. If samples were fractionated
off-line prior to `LC/MS`, a second `Excel` template will also be filled
out to link multiple `RAW` MS file names that are associated to the same
sample IDs. The default file name for the fractionation summary is
`frac_smry.xlsx`.\[3\] Unless otherwise mentioned, we will assume these
default file names throughout the document.

Columns in the `expt_smry.xlsx` are approximately divided into the
following three tiers: (1) `essential`, (2) `optional default` and (3)
`optional open`. We supply the required information of the TMT
experiments under the essential columns. The optional default columns
serve as the fields for convenient lookups in sample selection,
grouping, ordering, aesthetics etc. For instance, the program will by
default look for values under the `Color` column if no instruction was
given in the color coding of a PCA plot. The optional open fields on the
other hand allow us to define our own analysis and aesthetics. For
instance, we may openly define multiple columns of contrasts at
different levels of granularity for uses in statistical modelings.
Description of the column keys can be found from the help document by
entering `?proteoQ::load_expts` from a `R` console.

<img src="images\installation\three_tier_expt_smry.png" width="80%" style="display: block; margin: auto;" />

We next copy over a pre-compiled `expt_smry.xlsx` and a `frac_smry.xlsx`
to the working directory:

``` r
cptac_expt_1(dat_dir)
cptac_frac_1(dat_dir)
```

We now have all the pieces that are required by `proteoQ` in place.
Let’s have a quick glance at the `expt_smry.xlsx` file. We note that
no reference channels were indicated under the column `Reference`. With
`proteoQ`, the `log2FC` of each species in a given sample is calculated
either (*a*) in relative to the reference(s) within each multiplex TMT
experiment or (*b*) to the mean of all samples in the same experiment if
reference(s) are absent. Hence, the later approach will be employed to
the exemplary data set that we are working with. In this special case,
the `mean(log2FC)` for a given species in each TMT experiment is
averaged from five `WHIM2` and five `WHIM16` aliquots, which are
biologically equivalent across TMT experiments.

#### 1.1.4 Load experiment

As a final step of the setup, we will load the experimental summary into
a work space:

``` r
library(proteoQ)
load_expts()
```

### 1.2 Summarise Mascot PSMs

PSMs are MS/MS events that lead to peptide identication at certain
confidence levels. The evidences in PSMs can then be summarised to
peptide and protein findings using various descriptive statistics. In
this section, we will apply `proteoQ` to summarise PSM data into peptide
and protein reports.

#### 1.2.1 normPSM

We start the section by processing the PSM files exported directly from
`Mascot` searches:

``` r
# process PSMs with in-function filtration of data by arguments `filter_`
normPSM(
  group_psm_by = pep_seq, 
  group_pep_by = gene, 
  fasta = c("~\\proteoQ\\dbs\\fasta\\refseq\\refseq_hs_2013_07.fasta", 
            "~\\proteoQ\\dbs\\fasta\\refseq\\refseq_mm_2013_07.fasta"), 
  rm_craps = TRUE,
  rm_krts = FALSE,
  annot_kinases = TRUE, 
  rm_outliers = FALSE, 
  plot_rptr_int = TRUE, 
  rptr_intco = 3000,  

  filter_psms_at = exprs(pep_expect <= .1, pep_score >= 15), 
  filter_psms_more = exprs(pep_rank == 1),
)
```

Note that at present the `log2FC` of PSMs are always aligned by median
centering across samples.\[4\] At `group_psm_by = pep_seq`, PSM entries
with the same primary peptide sequence but different variable
modifications will be grouped for analysis using descriptive statistics.
In case `group_psm_by = pep_seq_mod`, PSMs will be grouped alternatively
according to the unique combination of the primary sequences and the
variable modifications of peptides. Analogously, `group_pep_by` specify
the grouping of peptides by either protein accession names or gene
names. The `fasta` argument points to the location of a copy of the
RefSeq fasta files that were used in the corresponding MS/MS searches.
Additional options include `rm_craps`, `rm_krts`, `annot_kinases` et
al. More description of `normPSM` can be found by accessing its help
document via `?normPSM`.

Every time we execute the `normPSM` module, it will process the PSM data
from the ground up. In other words, it has no memory on prior
happenings. For instance, we might call `normPSM` again with a lower
threshold of reporter-ion intensity with `rptr_intco = 1000`. After
inspecting graphically the intensity distributions at `plot_rptr_int =
TRUE`, we decide to go with the new cut-off. The downward in
`rptr_intco` is *not* going to cause information lost. This is trivia
but worth mentioning here. As we will find out in following sections,
utilities in peptide and protein normalization do pass information onto
successive iterations.

#### 1.2.2 Outlier samples

For experiments that are proximate in the quantities of input materials,
there might still be unprecedented events that could have caused dipping
in the ranges of reporter-ion intensity for certain samples. With proper
justication, we might consider excluding the outlier samples from
further analysis. The sample removal and PSM re-processing can be
achieved by simply deleting the corresponding entries under the column
`Sample_ID` in `expt_smry.xlsx`, followed by the re-execution of
`normPSM()`.

#### 1.2.3 Outlier data entries

There is a subtle problem when we choose to remove PSM outliers at
`rm_outliers = TRUE`. Note that PSM outliers will be assessed at a
per-peptide-and-per-sample basis, which can be a slow process for large
data sets. To circumvent repeated efforts in finding PSM outliers, we
may initially set `rm_outliers = FALSE` and `plot_rptr_int = TRUE` when
executing `normPSM()`. This will allow us to first decide on an ultimate
threshold of reporter-ion intensity, before proceeding to the more
time-consuming procedure in PSM outlier removals.

#### 1.2.4 Variable arguments

The `normPSM` function can take additional, user-defined arguments of
`dot-dot-dot` (see Wickham 2019, ch. 6) for the row filtration of data
using logical conditions. In the above example, we have limited
ourselves to PSM entries with `pep_expect <= 0.1` and `pep_score >= 15`
by supplying the variable argument (vararg) of `filter_psms_at`. We
further filtered the data at `pep_rank == 1` with another vararg of
`filter_psms_more`. It makes no difference whether we put the conditions
in one or multiple statements:

``` r
normPSM(
  filter_psms_at = exprs(pep_expect <= .1, pep_score >= 15, pep_rank == 1), 
  ..., 
)
```

The creation and assignment of varargs need to follow a format of
`filter_blahblah = exprs(cdn1, cdn2, ..., cond_last)`. Note that the
names of varargs on the lhs start with the character string of `filter_`
to indicate the task of data filtration. On the rhs, `pep_expect`,
`pep_score` and `pep_rank` are column keys that can be found from the
PSM data. Backticks will be needed for column keys containing white
space(s) and/or special character(s): `` `key with space (sample id in
parenthesis)` ``.

I am new to `R`. It looks like that canonical `R` does not support the
straight assignment of logical expressions to function arguments. To get
around this, I took advantage of the facility of non-standard evaluation
in `rlang` package in that the logical conditions are supplied within
the round parenthesis after `exprs`. Next, the `proteoQ` program will
obtain the expression(s) on the rhs of each vararg statment by
performing a bare evaluation using `rlang::eval_bare`. Following that, a
tidy evaluation by `rlang::eval_tidy` will be coupled to a local
facility in `proteoQ` to do the real work of data filtrations ((see
Wickham 2019, ch. 20)).

The approach of data filtration taken by `normPSM` might at first looks
strange; however, it allows me to perform data filtration in a
integrated way. As mentioned in the beginning, a central theme of
`proteoQ` is to reduce or avoid direct data manipulations but utilizes
metadata to control both data columns and rows. With the
self-containedness in data filtration (and data ordering later), I can
readily recall and reproduce what I had done when revisiting the system
after an extended peroid. Otherwise, I would likely need *ad hoc*
operations by mouse clicks or writing ephemeral R scripts, and soon
forget what I have done.

#### 1.2.5 Courtesy

With `normPSM`, we can pretty much `filter_` data under any PSM columns
we like. In the above example, I have chosen to filter PSM entires by
their `pep_expect`, `pep_score` etc. There is a reason for this.

Let’s first consider a different column `pep_len`. The values underneath
are unique to both PSMs and peptides. As you might courteously agree,
*its time has not yet come* in terms of tentative data filtration by
peptide length. In other words, we can delay the filtration of peptide
entries by their sequence lengths when we are actually working with
peptide data. The summarization of PSMs to peptides is not going to
change the number of amino acid residues in peptides. By contrast, the
data under `pep_expect` are unique to PSMs, but not necessary to
peptides. This is obvious in that each of the PSM events of the same
peptide is likely to have its own confidence expectation in peptide
identification. Therefore, if we were to filter data by their
`pep_expect` values at a later stage of analysis, we would have lost the
authentic information in `pep_expect` for peptides with mulitple PSM
identifications. More specifically, the values under `pep_expect` in
peptide tables are the geometric-mean representation of PSM results (see
also section 4).

For this reason, I named the varargs `filter_psms_at` and
`filter_psms_more` in the above `normPSM` examples. This allows me to
readily recall that I was filtering data based on criteria that are
specific to PSMs.

#### 1.2.6 purgePSM

To finish our discussion of PSM processing, let us consider having one
more bash in data cleanup. The corresponding utility is `purgePSM`. It
performs data purging by the CV of peptides, measured from contributing
PSMs within the same sample. Namely, quantitations that have yielded
peptide CV greater than a user-supplied cut-off will be replaced with
NA.

The `purgePSM` utility reads files `\PSM\TMTset1_LCMSinj1_PSM_N.txt`,
`\PSM\TMTset1_LCMSinj2_PSM_N.txt` etc. from a preceding step of
`normPSM`. To revert programmatically the changes made by `purgePSM`, we
would need to start over with `normPSM`. Alternatively, we may make a
temporary copy of these files for a probable undo.

This process takes place sample (column)-wisely while holding the places
for data points that have been nullified. It is different to the above
row filtration processes by `filter_` in that there is no *row removals*
with purging, not until all-NA rows are encountered.

Earlier in section 1.2.1, we have set `plot_log2FC_cv = TRUE` by default
when calling `normPSM`. This will plot the distributions of the CV of
peptide log2FC. In the event of `plot_log2FC_cv = FALSE`, we can have a
second chance in visualzing the distributions of peptide CV before any
permanent data nullification:

``` r
purgePSM ()
```

Taking the sample entries under `TMT_Set` one and `LCMS_Injection` one
in `label_scheme.xlsx` as an example, we can see that a small portion of
peptides have CV greater than 0.5 at log2 scale (**Figure 1A**).

<img src="images\psm\purge\psm_no_purge.png" title="**Figure 1A-1C.** CV of peptide log2FC. Left: no CV cut-off; middle: CV cut-off at 0.5; right: CV cut-off at 95 percentile." alt="**Figure 1A-1C.** CV of peptide log2FC. Left: no CV cut-off; middle: CV cut-off at 0.5; right: CV cut-off at 95 percentile." width="30%" style="display: block; margin: auto;" /><img src="images\psm\purge\psm_maxcv_purge.png" title="**Figure 1A-1C.** CV of peptide log2FC. Left: no CV cut-off; middle: CV cut-off at 0.5; right: CV cut-off at 95 percentile." alt="**Figure 1A-1C.** CV of peptide log2FC. Left: no CV cut-off; middle: CV cut-off at 0.5; right: CV cut-off at 95 percentile." width="30%" style="display: block; margin: auto;" /><img src="images\psm\purge\psm_qt_purge.png" title="**Figure 1A-1C.** CV of peptide log2FC. Left: no CV cut-off; middle: CV cut-off at 0.5; right: CV cut-off at 95 percentile." alt="**Figure 1A-1C.** CV of peptide log2FC. Left: no CV cut-off; middle: CV cut-off at 0.5; right: CV cut-off at 95 percentile." width="30%" style="display: block; margin: auto;" />

Quantitative differences greater than 0.5 at a log2 scale is relatively
large in TMT experiments,\[5\] which can be in part ascribed to a
phenomenum called peptide co-isolation and co-fragmentation in reporter
ion-based MS experiments. We might, for instance, perform an additional
cleanup by removing column-wisely data points with CV greater than 0.5
(**Figure 1B**):

``` r
purgePSM (
  max_cv = 0.5,
)
```

The above method using a flat cut-off would probably fall short if the
ranges of CV are considerably different across samples (see [Lab
3.1](###%203.1%20Reference%20choices)). Alternatively, we can remove
low-quality data points using a CV percentile, let’s say at 95%, for
each sample (**Figure 1C**):

``` r
# copy back `\PSM\TMTset1_LCMSinj1_PSM_N.txt` etc. before proceed
# otherwise the net effect will be additive to the prior(s)
purgePSM (
  pt_cv = 0.95,
)
```

In the event of both `pt_cv` and `max_cv` being applied to nullify data,
they follow the precedence of `pt_cv > max_cv`. When needed, we can
overrule the default by executing `purgePSM` sequentially at a custom
order:

``` r
# at first no worse than 0.5
purgePSM (
  max_cv = 0.5,
)

# next `pt_cv` on top of `max_cv`
purgePSM (
  pt_cv = 0.95,
)
```

The data purge is also additive w.r.t. to repetative analysis. In the
following example, we are actually perform data cleanup at a CV
threshold of 90%:

``` r
# at first 95%
purgePSM (
  pt_cv = 0.95,
)

# next 95% of 95%
purgePSM (
  pt_cv = 0.95,
)
```

While multiple PSMs carry information about the precision in peptide
measures, the above single-sample variance does not inform sampling
errors prior to peptide separations. For instance, the same peptide
species from a given sample remain indistinguishable/exchangeable prior
to the off-line fractionation. As a result, the CV shown by `normPSM` or
`purgePSM` mainly tell us the uncertainty of measures beyond the point
of peptide parting.

*NB:* CV is sensitive to outliers and some large CV in peptide
quantitations may be merely due to a small number of bad measures.
Although the option of `rm_outliers` was set to `FALSE` during our
earlier call to `normPSM`, I think it is generally a good idea to have
`rm_outliers = TRUE`.

### 1.3 Summarize PSMs to peptides

In this section, we summarise the PSM results to peptides with `normPep`
and optional `purgePep`.

#### 1.3.1 normPep

The core utility for the summary of PSMs to peptides is `normPep`:

``` r
# peptide reports
normPep(
  method_psm_pep = median,
  range_log2r = c(5, 95),
  range_int = c(5, 95),  
  
  method_align = MGKernel,
  n_comp = 3,
  seed = 749662,
  maxit = 200,
  epsilon = 1e-05,

  filter_peps_by = exprs(pep_len <= 50),
)
```

It loads the PSM tables from the preceding `normPSM` procedure and
summarize them to peptide data using various descriptive statistics (see
also Section 4). For `intensity` and `log2FC` data, the summarization
method is specified by argument `method_psm_pep`, with `median` being
the default. The parameters `range_log2r` and `range_int` outline the
ranges of peptide `log2FC` and reporter-ion intensity, respectively, for
use in defining the CV and scaling the `log2FC` across samples.

The `log2FC` of peptide data will be aligned by `median centering`
across samples by default. If `method_align = MGKernel` is chosen,
`log2FC` will be aligned under the assumption of multiple Gaussian
kernels.\[6\] The companion parameter `n_comp` defines the number of
Gaussian kernels and `seed` set a seed for reproducible fittings.
Additional parameters, such as, `maxit` and `epsilon`, are defined in
and for use with
[`normalmixEM`](https://cran.r-project.org/web/packages/mixtools/mixtools.pdf).
For more description of `normPep`, one can access its help document via
`?normPep`.

#### 1.3.2 Variable arguments

Similar to `normPSM`, we can subset data by column keys via the varargs
linked to `filter_`. In the exemplary vararg statement of
`filter_peps_by`, we exlcude longer peptide sequences with more than 50
amino acid residues. If we are interested in human, but not mouse,
peptides from the pdx samples, we can specify similarly that `species ==
"human"`. Sometimes, it may remain unclear on proper data filtration at
the early stage of analysis. In that case, we may need additional
quality assessments that we will soon explore. Alternatively, we may
keep as much information as possible and apply varargs in downstream
analysis.

You may wonder when does the data subsetting via varargs of `filter_`
occur in the `normPep` process? This is an importance question because
the end results depend on where the filtration step is anchored. Behind
the scene when the `normPep` is first called, the individual pieces of
PSM data are each summarized to peptide data with the PSM-specific
information being described statistically. The varargs of `filter_` is
then employed against the column keys in the so-derived peptide tables.

I think this is a suitable choice in that we can have done PSM-specific
filtration during the `normPSM` step, should there be such needs. For
this reason, the individual peptide tables are placed immediately under
the `Peptide` folder for convenient lookups of column keys that are
available for `filter_`.

#### 1.3.3 Utility elements

The `normPep` utility has three major components, namely, (1)
PSM-to-peptide summarization, (2) peptide data combination and (3)
normalization. The utility is also meant for iterative uses. For
instance, we may re-normalize the peptide data with a different range of
`range_log2r`, by toggling `method_align` between `MC` and `MGKernel`,
against a list of protein candidates, or mixed-bedding with `MC` for
some samples and `MGKernel` for some others, etc.

The `cache` argument defaulted at `TRUE` can speed up the process a bit
by loading directly the `Peptide.txt` from a most recent execution of
`normPep`. For changes that require the re-compilation of `Peptide.txt`,
such as a different set of varargs of `filter_`, the utility will
re-execute both steps (2) and (3). There are a few rules, for example,
how the method is dispatched from `n_comp = 3` to `n_comp = 2` etc. I am
not going to go into the great details here but refer to the examples in
`proteoQ::?normPep`. Note that the documentation remains a
work-in-progress with more examples to come.

There is another group of varargs, `slice_`, that work with an image of
the loaded `Peptide.txt` in data normalization. We will go over the
applications and motivations of the `slice_` varargs with examples in
Section 1.3.7. Technically, they are just another `filter_` anchored at
a different location within `normPep`. What I meant to stress here is
that the re-execution of `normPep` with new settings in `slice_` will
only involve step (3), as it works against the image of `Peptide.txt`.

Overall, I think it might be benefical to go over some techninal details
of `normPep` in the document. This would allow us to confidently apply
the utility to meet our needs. The bottom line is this: we can always
set `cache = FALSE` and move on. This will run the `normPep` utility
against PSM tables with a fresh start, which comes at the costs of
computer time and, more importantly, the versality that we will soon
discuss.

#### 1.3.4 purgePep

Analogously to the PSM processing, we may nullify data points of
peptides by specifying a cut-off in their protein CVs:

``` r
# no purging
purgePep()

# or purge column-wisely by max CV
purgePep (
  max_cv = 0.5,
  filename = "by_maxcv.png",  
)

# or purge column-wisely by CV percentile
# remember the additive effects
purgePep (
  pt_cv = 0.5,
  filename = "by_ptcv.png",
)
```

*NB:* The above single-sample CVs of proteins are based on ascribing
peptides, which thus do not inform the uncertainty in sample handling
prior to the parting of protein entities, for example, the enzymatic
breakdown of proteins in a typical MS-based proteomic workflow. On the
other hand, the peptide `log2FC` have been previously summarized by the
median statistics from contributing PSMs. Putting these two togother,
the CV by `purgePep` describes approximately the uncentainty in sample
handling from the breakdown of proteins to the off-line fractionation of
peptides.

#### 1.3.5 pepHist

We next compare the `log2FC` profiles with and without scaling
normalization:\[7\]

``` r
# without scaling
pepHist(
  scale_log2r = FALSE, 
  ncol = 10,
)

# with scaling  
pepHist(
  scale_log2r = TRUE, 
  ncol = 10,
)
```

The `pepHist` utility plots the histograms of peptide `log2FC`. It
further bins the data by their contributing reporter-ion intensity.

##### 1.3.5.1 Sample subset

By default, the above calls will look for none void entries under column
`Select` in `expt_smry.xlsx`. This will results in histogram plots with
60 panels in each, which may not be easy to explore as a whole. In
stead, we will break the plots down by their data origins. We begin with
modifying the `expt_smry.xlsx` file by adding the columns `BI`, `JHU`
and `PNNL`. Each of the new columns includes sample entries that are
tied to their laboratory origins (the columns are actually already in
the `expt_smry.xlsx`).

[![Select
subsets](https://img.youtube.com/vi/3B5et8VY3hE/0.jpg)](https://www.youtube.com/embed/3B5et8VY3hE)

We now are ready to plot histograms for each subset of the data.\[8\] In
this document, we only display the plots using the `BI` subset:

``` r
# without scaling 
pepHist(
  scale_log2r = FALSE, 
  col_select = BI,
  ncol = 5,
  filename = hist_bi_n_1.png, 
)

# with scaling 
pepHist(
  scale_log2r = TRUE, 
  col_select = BI,
  ncol = 5,
  filename = hist_bi_z_1.png, 
)
```

*NB*: We interactively told `pepHist()` that we are interested in sample
entries under the newly created `BI` column. Behind the scene, the
interactions are facilitated by
[`openxlsx`](https://cran.r-project.org/web/packages/openxlsx/openxlsx.pdf)
via the reading of the `Setup` workbook in `expt_smry.xlsx`. We also
supply a file name, assuming that we want to keep the earlierly
generated plots with default file names of `Peptide_Histogram_N.png` and
`Peptide_Histogram_Z.png`.

<img src="images\peptide\histogram\hist_bi_n.png" title="**Figure 2A-2B.** Histograms of peptide log2FC. Top: `scale_log2r = FALSE`; bottom, `scale_log2r = TRUE`" alt="**Figure 2A-2B.** Histograms of peptide log2FC. Top: `scale_log2r = FALSE`; bottom, `scale_log2r = TRUE`" width="85%" style="display: block; margin: auto;" /><img src="images\peptide\histogram\hist_bi_z.png" title="**Figure 2A-2B.** Histograms of peptide log2FC. Top: `scale_log2r = FALSE`; bottom, `scale_log2r = TRUE`" alt="**Figure 2A-2B.** Histograms of peptide log2FC. Top: `scale_log2r = FALSE`; bottom, `scale_log2r = TRUE`" width="85%" style="display: block; margin: auto;" />

As expected, both the widths and the heights of `log2FC` profiles become
more comparable after the scaling normalization. However, such
adjustment may cause artifacts when the standard deviaiton across
samples are genuinely different. I typically test `scale_log2r` at both
`TRUE` and `FALSE`, then make a choice in data scaling together with my
a priori knowledge of the characteristics of both samples and
references.\[9\] We will use the same data set to illustrate the impacts
of reference selections in scaling normalization in [Lab
3.1](###%203.1%20Reference%20choices).

##### 1.3.5.2 Side effects

It should also be noted that the curves of Gaussian density in
histograms are calculated during the latest call to `normPep(...)` with
the option of `method_align = MGKernel`. There is a useful side effect
when comparing leading and lagging profiles between an `MC` and an
`MGKernel` alignment. In the following barebone example, we align
differently the peptide `log2FC` with the default method of median
centering:

``` r
normPep()
```

We then visuzlize the histograms of the ratio profiles (**Figure 2C**):

``` r
pepHist(
  scale_log2r = TRUE, 
  col_select = BI,
  ncol = 5,
  filename = hist_bi_z_mc_2.png, 
)
```

Within this README, the preceding example that involves `normPep(...)`
at `method_align = MGKernel` is given in section 1.3.1. In this case, a
comparison between the present and the prior will reveal the difference
in ratio alignments between a median centering and a three-Gaussian
assumption. More examples can be found from the help document via
`?normPep` and `?pepHist`.

<img src="images\peptide\histogram\hist_bi_z_mc.png" title="**Figure 2C-2D.** Histograms of peptide log2FC. Top: median-centering for all samples; bottom: `W2.BI.TR2.TMT1` and `W2.BI.TR2.TMT2` aligned differently by Gaussian density" alt="**Figure 2C-2D.** Histograms of peptide log2FC. Top: median-centering for all samples; bottom: `W2.BI.TR2.TMT1` and `W2.BI.TR2.TMT2` aligned differently by Gaussian density" width="85%" style="display: block; margin: auto;" /><img src="images\peptide\histogram\sel_norm_and_fil.png" title="**Figure 2C-2D.** Histograms of peptide log2FC. Top: median-centering for all samples; bottom: `W2.BI.TR2.TMT1` and `W2.BI.TR2.TMT2` aligned differently by Gaussian density" alt="**Figure 2C-2D.** Histograms of peptide log2FC. Top: median-centering for all samples; bottom: `W2.BI.TR2.TMT1` and `W2.BI.TR2.TMT2` aligned differently by Gaussian density" width="85%" style="display: block; margin: auto;" />

#### 1.3.6 Renormalize data against column subsets

A multi-Gaussian kernel can fail capturing the `log2FC` profiles for a
subset of samples. This is less an issue with a small number of samples.
Using a trial-and-error approach, we can start over with a new
combination of parameters, such as a different `seed`, and/or a
different range of `range_log2r` etc. However, the one-size-fit-all
attempt may remain inadequate when the number of samples is relatively
large. The `proteoQ` allows users to *focus* fit aganist selected
samples. This is the job of argument `col_refit`. Let’s say we want to
re-fit the `log2FC` for samples `W2.BI.TR2.TMT1` and `W2.BI.TR2.TMT2`.
We simply add a column, which I named it `Select_sub`, to
`expt_smry.xlsx` with the sample entries for re-fit being indicated
under the column:

<img src="images\peptide\histogram\partial_refit.png" width="80%" style="display: block; margin: auto;" />

We may then execute the following codes with argument `col_refit` being
linked to the newly created column:

``` r
normPep(
  method_align = MGKernel, 
  range_log2r = c(5, 95), 
  range_int = c(5, 95), 
  n_comp = 3, 
  seed = 749662, 
  maxit = 200, 
  epsilon = 1e-05, 
  
  col_refit = Select_sub,
)

pepHist(
  scale_log2r = TRUE, 
  col_select = BI,
  ncol = 5,
  filename = mixed_bed_3.png, 
)
```

In the preceding execution of barebone `normPep()`, samples were aligned
by median centering (**Figure 2C**). As expected, the current partial
re-normalization only affects samples `W2.BI.TR2.TMT1` and
`W2.BI.TR2.TMT2` (**Figure 2D**). In other words, samples
`W2.BI.TR2.TMT1` and `W2.BI.TR2.TMT2` are now aligned by their Gaussian
densities whereas the remaining are by median centering. The combination
allows us to align any sample by either the `MC` or the `MGKernel`
method. If you have been long to perform independant sample
normalization, the two-step procedure might represent a solution.

Now let’s consider what happens if we apply additionally the `filter_`
vararg:

``` r
normPep(
  method_align = MGKernel, 
  range_log2r = c(5, 95), 
  range_int = c(5, 95), 
  n_comp = 3, 
  seed = 749662, 
  maxit = 200, 
  epsilon = 1e-05, 
  
  col_refit = Select_sub,
  
  filter_prots_by_sp = exprs(species == "human"), 
)

pepHist(
  scale_log2r = TRUE, 
  col_select = BI,
  ncol = 5,
  filename = human_4.png, 
)
```

The answer is simple: the filtration criteria of `species == "human"`
will apply to all samples\! This is because `species` in a column key in
input data frame. Whatever rows fail on the logical condition, they will
be removed entirely across all samples.

#### 1.3.7 Renormalize data against row subsets

We have earlierly applied the varargs of `filter_` to subset data rows.
With this type of arguments, data entries that have failed the
filtration criteria will be removed for indicated analysis. This is
often not an issue in informatic analysis and visualization as we do not
typically store the altered inputs on external devices at the end.
Sometimes we may however need to carry out similar tasks based on
partial inputs and update the complete set of data for future uses. One
of the circumstances is model parameterization by a data subset and to
apply the finding(s) to update the complete set.

##### 1.3.7.1 Vararg `slice_`

Here we will apply the idea for ratio normalization against a subset of
peptide entries and update the original peptide table. We use a second
category of vararg termed `slice_` for data normalization based on
certain rows of data. The utility can futher be coupled to the
aforementioned `col_refit` argument for selected sample(s). In the
following example, we normalize the `log2FC` using the partial data from
argument `slice_at`, for samples under the column `Select_sub` in
`expt_smry.xlsx`:

``` r
normPep(
  method_align = MGKernel, 
  range_log2r = c(5, 95), 
  range_int = c(5, 95), 
  n_comp = 3, 
  seed = 749662, 
  maxit = 200, 
  epsilon = 1e-05, 
  
  # refit samples under column Select_sub in expt_smry.xlsx
  col_refit = Select_sub,   
  
  # partial data from the selected sample(s) for use in normalization 
  slice_at = exprs(prot_n_psm >= 10, pep_n_psm >= 6),   
)

pepHist(
  scale_log2r = TRUE,
  col_select = BI,
  ncol = 5,
  filename = slicerows_for_selcols_5.png,
)
```

The underlying mechanism is simple: `col_select` defines the sample
*columns* and `slice_at` defines the data *rows* in `Peptide.txt`; and
only the intersecting area between columns and rows will be subject
additively to data alignment. The same pattern will apply every time we
execute `normPep()` with corresponding parameters.

Having had the above picture in mind, it becomes self-explanatory that
the normlization processes against partial data are `additive` and
`permutable`. This means that we can start from strict to loose
conditions or *vice versa*. In the example shown below, we first
normalize against samples under column `JHU` with conditions by
`slice_jhu`, followed by additional procedures against the samples under
column `BI` with conditions by `slice_bi`:

``` r
normPep(
  method_align = MGKernel, 
  range_log2r = c(5, 95), 
  range_int = c(5, 95), 
  n_comp = 3, 
  seed = 749662, 
  maxit = 200, 
  epsilon = 1e-05, 
  col_refit = JHU,
  slice_jhu = exprs(prot_n_psm >= 8, prot_n_pep >= 6),
)

normPep(
  method_align = MGKernel, 
  range_log2r = c(5, 95), 
  range_int = c(5, 95), 
  n_comp = 3, 
  seed = 749662, 
  maxit = 200, 
  epsilon = 1e-05, 
  col_refit = BI,
  slice_bi = exprs(prot_n_psm >= 10, pep_n_psm >= 5),
)

pepHist(
  scale_log2r = TRUE,
  col_select = BI,
  xmin = -2, 
  xmax = 2,
  ncol = 5,
  filename = additive_6.png,
)
```

I have noted earlierly that `slice_` is nothing more than another
`filter_`. The only difference is that the `slice_` varargs are assessed
later during the normalization steps. In other words, `slice_` defines
the data rows for mere normalization purpose and do not remove data
rows. By contrast, `filter_` performs data preprocessing with row
removals by condition. We can apply `slice_` together with `filter_`
too, but the combination seems overkilling for most of our tasks.

##### 1.3.7.2 Housekeepers

Now it becomes elementary if we were to normalize data against
housekeeping proteins. Let’s say we have `ACTB` and `GAPDH` in mind as
housekeeping invariants among the proteomes, and of course we have good
accuracy in their `log2FC`. We simply `slice` the proteins out for use
as a normalizer:

``` r
normPep(
  method_align = MC, 
  range_log2r = c(5, 95), 
  range_int = c(5, 95), 
  col_refit = Select_sub,
  slice_hskp = exprs(gene %in% c("ACTB", "GAPDH")),
)

pepHist(
  scale_log2r = TRUE, 
  col_select = BI,
  ncol = 5,
  filename = housekeepers_7.png, 
)
```

Note that I chose `method_align = MC` in the above. There are only 67
rows available for `col_refit` samples after slicing out ACTB and
GAPDH\! The number of data points is too scare for fitting the selected
samples against a 3-component Gaussian.

##### 1.3.7.3 Start with median centering

In section 1.3.7.1, we started `normPep()` with `method_align =
MGKernel`. There is a subtle difference if we start alternatively with
the default of `method_align = MC`. Detailed examples can be found from
`Mixed-bed (2): begin with MC` in the help document via `?normPep`. The
short answer is that `MGKernel` is a *stronger* condition than `MC` with
additional outputs in parameters. As a result, subsequent partial
fittings with `MC` can build on the `MGKernel` priors. The *vice versa*,
however, does not hold.

### 1.4 Summarize peptides to proteins

In this section, we summarise peptides to proteins, for example, using a
two-component Gaussian kernel and customized filters.

#### 1.4.1 normPrn

The core utility for the summary of peptides to proteins is `normPrn`:

``` r
# protein reports
normPrn(
    method_pep_prn = median, 
    range_log2r = c(20, 95), 
    range_int = c(5, 95),   
    
    method_align = MGKernel, 
    n_comp = 2, 
    seed = 749662, 
    maxit = 200, 
    epsilon = 1e-05, 
    
    filter_prots_by = exprs(prot_n_pep >= 2),   
)
```

It loads `Peptide.txt` from the preceding `normPep` procedure and
summarize them to protein data using various descriptive statistics (see
also Section 4). For `intensity` and `log2FC` data, the summarization
method is specified by argument `method_pep_prn`, with `median` being
the default. The parameters `range_log2r` and `range_int` outline the
ranges of protein `log2FC` and reporter-ion intensity, respectively, for
use in defining the CV and scaling the `log2FC` across samples.

Similar to `normPep`, the `log2FC` of protein data can be aligned by
either `MC` or `MGKernel`, with `n_comp`, `seed` ect being the companion
arguments for the later. For more description of `normPrn`, one can
access its help document via `?normPrn`.

#### 1.4.2 Utility elements

There is a mild difference between `normPrn` and `normPep`. The
`normPrn` utility has only two main components, namely, (1)
peptide-to-protein summarization and (2) normalization. At the default
`cache = TRUE`, the utility will load directly the `Protein.txt` derived
from the most recent execution of `normPrn`. For changes that require
the re-computation of `Protein.txt`, the utility will start over by
loading peptide data again.

The varargs of `filter_` for row filtration is anchored immediately
after the `Peptide.txt` is loaded and thus applied to the column keys
therein. The examplary vararg of `filter_prots_by` will remove entries
with less than two counts of quantifiable peptide sequences under a
proposed protein. Note that the counts exclude entries that are void in
reporter-ion intensity or filtered by users (see also Section 4.1.1).

#### 1.4.3 prnHist

Similar to the peptide summary, we can inspect the alignment and the
scale of ratio profiles:

``` r
# without scaling
prnHist(
  scale_log2r = FALSE, 
  col_select = BI,
  ncol = 5,
  filename = hist_bi_n.png, 
)

# with scaling
prnHist(
  scale_log2r = TRUE, 
  col_select = BI,
  ncol = 5,
  filename = hist_bi_z.png, 
)
```

For simplicity, we only display the histograms with scaling
normalization (**Figure 2E**).

<img src="images\protein\histogram\hist_bi_z.png" title="**Figure 2E-2F.** Histograms of protein log2FC at `scale_log2r = TRUE`. Left: before filtration; right, after filtration" alt="**Figure 2E-2F.** Histograms of protein log2FC at `scale_log2r = TRUE`. Left: before filtration; right, after filtration" width="50%" style="display: block; margin: auto;" /><img src="images\protein\histogram\hist_bi_z_npep10.png" title="**Figure 2E-2F.** Histograms of protein log2FC at `scale_log2r = TRUE`. Left: before filtration; right, after filtration" alt="**Figure 2E-2F.** Histograms of protein log2FC at `scale_log2r = TRUE`. Left: before filtration; right, after filtration" width="50%" style="display: block; margin: auto;" />

##### 1.4.3.1 Row filtration

Just as in `normPep` and `normPrn`, the varargs of `filter_` are
applicable to both `pepHist` and `prnHist` for the row filtration of
data. Despite, there is a difference.

As you may recall, `normPep` or `normPrn` are bridging utilities that
transform data either from PSMs to peptides or peptides to proteins. We
also navigated through the ambiguity that could have been caused by the
makeover, by knowing that the `filter_` arguments are anchored
immediately after the loading of peptide or protein data.

Simply enough, the `filter_` in `pepHist` and `prnHist` are
no-brainers\! As indicated in the names, `pepHist` works directly
against `Peptide.txt` and `prnHist` against `Protein.txt`, for histogram
visualizations. The rule can largely be held for the remaining utilities
throughout `proteoQ`.\[10\]

##### 1.4.3.2 Side effects

In section 1.3.5.2, we used `pepHist` to illustrate the side effects in
histogram visualization when toggling the alignment methods between `MC`
and `MGKernel`. In the following, we will show another example of side
effects using the protein data.

We prepare the ratio histograms for proteins with ten or more
quantifying peptides:

``` r
# without scaling
prnHist(
  scale_log2r = FALSE, 
  col_select = BI,
  ncol = 5,
  
  filter_prots_by = exprs(prot_n_pep >= 10),
  filename = hist_bi_n_npep10.png, 
)

# with scaling
prnHist(
  scale_log2r = TRUE, 
  col_select = BI,
  ncol = 5,
  
  filter_prots_by = exprs(prot_n_pep >= 10),
  filename = hist_bi_z_npep10.png, 
)
```

The density curves are based on the latest call to `normPrn(...)` with
`method_align = MGKernel` (**Figure 2E**). For simplicity, we again only
show the current plots at `scale_log2_r = TRUE` (**Figure 2F**). The
comparison between the lead and the lag allows us to visualize the
heteroscedasticity in data and in turn inform new parameters in data
renormalization.

### 1.5 scale\_log2\_r

Up to this point, we might have reach a consensus on the choice of
scaling normalization. If so, it may be plausible to set the value of
`scale_log2r` under the Global environment, which is typically the `R`
console that we are interacting with.

``` r
# if agree
scale_log2r <- TRUE

# or disagree
scale_logr <- FALSE
```

In this way, we can skip the repetitive setting of `scale_log2r` in our
workflow from this point on, and more importantly, prevent ourselves
from peppering the values of `TRUE` or `FALSE` in `scale_log2r` from
analysis to analysis.

### 1.5 Summarize MaxQuant results

In this section, we will process MaxQuant PSMs using the same set of
data from CPTAC. The name of a PSM file containg reporter-ion
intensities is `msms.txt` defaulted by MaxQuant. In the event of
multiple `msms.txt` files for processing, the names need to be formatted
in that they all start with `msms` and end with the `.txt` extension.

The file sizes of the `msms.txt` are relatively large for data used in
the demonstration. For simplicity, we will only use the subset that
belong to batch one in the CPTAC example. Even so, direct installation
by `devtools::install_github` is not yet feasible at this point for
large files hosted through [LFS](https://git-lfs.github.com/). One
resort is to install [Github Desktop](https://desktop.github.com/), find
<https://github.com/qiangzhang503/proteoQDB.git>, fetch the files and
make a local installation through something like `devtools::install(pkg
= "~\\GitHub\\proteoQDB")`. If all goes well with the local
installation, we will load `proteoQDB` and copy over the PSM files
therein to a working directory:

``` r
# fasta files to database directory if not yet available
library(proteoQDA)
copy_refseq_hs("~\\proteoQ\\dbs\\fasta\\refseq")
copy_refseq_mm("~\\proteoQ\\dbs\\fasta\\refseq")

# exemplary PSM data to working directory
library(proteoQDB)
dir.create("C:\\The\\MQ\\Example", recursive = TRUE, showWarnings = FALSE)
dat_dir <- c("C:\\The\\MQ\\Example")
cptac_mqpsm_txt(dat_dir)
```

Similarly, we copy over the corresponding `expt_smry.xlsx` and
`fract_smry.xlsx` files and load the experiment:

``` r
# metadata to working directory
cptac_mqpsm_expt(dat_dir)
cptac_mqpsm_frac(dat_dir)

# metadata upload
library(proteoQ)
load_expts()
```

We next process the PSM data from MaxQuant and perform peptide and
protein normlizations. Note that some column keys in MaxQuant outputs
contain white space(s) and special character(s) such as parenthesis. In
these cases, we will need to quote the column keys with a pair of
backticks when applying varargs for data filtration.

``` r
# PSM
normPSM(
  group_psm_by = pep_seq, 
  group_pep_by = gene, 
  fasta = c("~\\proteoQ\\dbs\\fasta\\refseq\\refseq_hs_2013_07.fasta",
            "~\\proteoQ\\dbs\\fasta\\refseq\\refseq_mm_2013_07.fasta"), 
  rptr_intco = 3000,                    
  corrected_int = TRUE,
  rm_reverses = TRUE,
  rm_craps = TRUE,
  rm_krts = FALSE,
  rm_outliers = FALSE, 
  annot_kinases = TRUE, 
  plot_rptr_int = TRUE, 
  plot_log2FC_cv = TRUE, 
  
  filter_peps = exprs(PEP <= 0.1), 
)

# optional PSM purging
purgePSM()

# peptides
normPep(
  method_psm_pep = median, 
  method_align = MGKernel, 
  range_log2r = c(5, 95), 
  range_int = c(5, 95), 
  n_comp = 3, 
  seed = 749662, 
  maxit = 200, 
  epsilon = 1e-05, 
  # filter_by = exprs(pep_n_psm >= 2, species == "human"),
)

# optional peptide purging
purgePep()

# proteins
normPrn(
  use_unique_pep = TRUE, 
  method_pep_prn = median, 
  method_align = MGKernel, 
  range_log2r = c(20, 95), 
  range_int = c(5, 95), 
  n_comp = 2, 
  seed = 749662, 
  maxit = 200, 
  epsilon = 1e-05, 
  filter_by = exprs(prot_n_pep >= 2),
)
```

Following the normalizations and cleanups, we can carry out analogous
data visualization using the intensity-coded histograms. Note that I
have renamed some column keys in the PSM, peptide and protein tables to
match their counterparts in `Mascot`. The changes allow me to keep the
code more succinct. I apologize if you find it all more difficult to
deal with the new names.

### 1.6 Summarize Spectrum Mill results

The procedures that have been applied to Mascot and MaxQuant examples
are also suitable for Spectrum Mill PSMs. There is one difference that
the file names of PSMs need to start with `PSMexport` and end with the
`ssv` extension. For simplicity, I will only show an exemple in PSM
processing:

``` r
normPSM(
  group_psm_by = pep_seq_mod, 
  group_pep_by = gene,
  fasta = c("~\\proteoQ\\dbs\\fasta\\refseq\\refseq_hs_2013_07.fasta",
            "~\\proteoQ\\dbs\\fasta\\refseq\\refseq_mm_2013_07.fasta"), 
  rptr_intco = 3000,
  rm_craps = TRUE,
  rm_krts = FALSE,
  rm_outliers = FALSE, 
  annot_kinases = TRUE, 
  plot_rptr_int = TRUE, 
  plot_log2FC_cv = TRUE, 
  
  filter_peps = exprs(score >= 10), 
)
```

### 1.7 Workflow scripts

Scripts that were used in this document can be accessed via:

``` r
system.file("extdata", "mascot_scripts.R", package = "proteoQ")
system.file("extdata", "maxquant_scripts.R", package = "proteoQ")
```

## 2 Basic informatics

In this section I illustrate the following applications of `proteoQ`:

  - Basic informatic analysis against peptide and protein data.
  - Linear modeling using contrast fits

Unless otherwise mentioned, the `in-function filtration` of data by
varargs of `filter_` is available throughout this section of informatic
analysis. Row ordering of data, indicated by `arrange_`, is available
for heat map applications using `pepHM` and `prnHM`.

### 2.1 MDS and PCA plots

We first visualize MDS, PCA and Euclidean distance against the peptide
data. We start with metric MDS for peptide data:

``` r
# all data
pepMDS(
  show_ids = FALSE,
)
```

<img src="images\peptide\mds\peptide_mds.png" title="**Figure 3A.** MDS of peptide log2FC at `scale_log2r = TRUE`" alt="**Figure 3A.** MDS of peptide log2FC at `scale_log2r = TRUE`" width="45%" style="display: block; margin: auto;" />

It is clear that the WHIM2 and WHIM16 samples are well separated by the
Euclidean distance of `log2FC` (**Figure 3A**). We next take the `JHU`
data subset as an example to explore batch effects in the proteomic
sample handling:

``` r
# `JHU` subset
pepMDS(
  col_select = JHU,
  filename = MDS_JHU.png,
  show_ids = FALSE,
)
```

<img src="images\peptide\mds\mds_jhu.png" title="**Figure 3B-3C.** MDS of peptide log2FC for the `JHU` subset. Left: original aesthetics; right, modefied aesthetics" alt="**Figure 3B-3C.** MDS of peptide log2FC for the `JHU` subset. Left: original aesthetics; right, modefied aesthetics" width="45%" style="display: block; margin: auto;" /><img src="images\peptide\mds\mds_jhu_new_aes.png" title="**Figure 3B-3C.** MDS of peptide log2FC for the `JHU` subset. Left: original aesthetics; right, modefied aesthetics" alt="**Figure 3B-3C.** MDS of peptide log2FC for the `JHU` subset. Left: original aesthetics; right, modefied aesthetics" width="45%" style="display: block; margin: auto;" />

We immediately spot that all samples are coded with the same color
(**Figure 3B**). This is not a surprise as the values under column
`expt_smry.xlsx::Color` are exclusively `JHU` for the `JHU` subset. For
similar reasons, the two different batches of `TMT1` and `TMT2` are
distinguished by transparency, which is governed by column
`expt_smry.xlsx::Alpha`. We may wish to modify the aesthetics using
different keys: e.g., color coding by WHIMs and size coding by batches,
without the recourse of writing new R scripts. One solution is to link
the attributes and sample IDs by creating additional columns in
`expt_smry.xlsx`. In this example, we have had coincidentally prepared
the column `Shape` and `Alpha` to code WHIMs and batches, respectively,
for the `JHU` subset. Therefore, we can recycle them directly to make a
new plot (**Figure 3C**):

``` r
# new `JHU` subset
pepMDS(
  col_select = JHU,
  col_fill = Shape, # WHIMs  
  col_size = Alpha, # batches
  filename = MDS_JHU_new_aes.png,
  show_ids = FALSE,
)
```

Accordingly, the `prnMDS` performs `MDS` for protein data. For `PCA`
analysis, the corresponding functions are `pepPCA` and `prnPCA` for
peptide and protein data, respectively.

While `MDS` approximates Euclidean distances at a low dimensional space.
Sometimes it may be useful to have an accurate view of the distance
matrix. Functions `pepEucDist` and `prnEucDist` plot the heat maps of
Euclidean distance matrix for peptides and proteins, respectively. They
are wrappers of
[`pheatmap`](https://cran.r-project.org/web/packages/pheatmap/pheatmap.pdf).
Supposed that we are interested in visualizing the distance matrix for
the `JHU` subset:

``` r
# `JHU` subset
pepEucDist(
  col_select = JHU,
  annot_cols = c("Shape", "Alpha"),
  annot_colnames = c("WHIM", "Batch"), 
  
  # `pheatmap` parameters 
  display_numbers = TRUE, 
  number_color = "grey30", 
  number_format = "%.1f",
  
  clustering_distance_rows = "euclidean", 
  clustering_distance_cols = "euclidean", 
  
  fontsize = 16, 
  fontsize_row = 20, 
  fontsize_col = 20, 
  fontsize_number = 8, 
  
  cluster_rows = TRUE,
  show_rownames = TRUE,
  show_colnames = TRUE,
  border_color = "grey60", 
  cellwidth = 24, 
  cellheight = 24, 
  width = 14,
  height = 12, 
  
  filename = EucDist_JHU.png,
)
```

Parameter `annot_cols` defines the tracks to be displayed on the top of
distrance-matrix plots. In this example, we have choosen
`expt_smry.xlsx::Shape` and `expt_smry.xlsx::Alpha`, which encodes the
WHIM subtypes and the batch numbers, respectively. Parameter
`annot_colnames` allows us to rename the tracks from `Shape` and `Alpha`
to `WHIM` and `Batch`, respectively, for better intuition. We can
alternatively add columns `WHIM` and `Batch` if we choose not to recycle
and rename columns `Shape` and `Alpha`.

<img src="images\peptide\mds\eucdist_jhu.png" title="**Figure 3D.** EucDist of peptide log2FC at `scale_log2r = TRUE`" alt="**Figure 3D.** EucDist of peptide log2FC at `scale_log2r = TRUE`" width="45%" style="display: block; margin: auto;" />

### 2.2 Correlation plots

In this section, we visualize the batch effects through correlation
plots. The `proteoQ` tool currently limits itself to a maximum of 44
samples for a correlation plot. In the document, we will perform
correlation analysis against the `PNNL` data subset. By default, samples
will be arranged by the alphabetical order for entries under the column
`expt_smry.xlsx::Select`. We have learned from the earlier `MDS`
analysis that the batch effects are smaller than the differences between
`W2` and `W16`. We may wish to put the `TMT1` and `TMT2` groups
adjacient to each other for visualization of more nuance batch effects,
followed by the comparison of WHIM subtypes. We can achieve this by
supervising sample IDs at a customized order. In the `expt_smry.xlsx`,
We have prepared an `Order` column where samples within the `JHU` subset
were arranged in the descending order of `W2.TMT1`, `W2.TMT2`,
`W16.TMT1` and `W16.TMT2`. Now we tell the program to look for the
`Order` column for sample arrangement:

``` r
# peptide logFC
pepCorr_logFC(
  col_select = PNNL,
  col_order = Order, 
  filename = PNNL_pep_logfc.png,
)

# protein logFC
prnCorr_logFC(
  col_select = W2,
  col_order = Group,
  filename = PNNL_prn_logfc.png,
)
```

<img src="images\peptide\corrplot\corr_pnnl.png" title="**Figure 4A-4B.** Correlation of log2FC for the `PNNL` subset. Left: peptide; right, protein" alt="**Figure 4A-4B.** Correlation of log2FC for the `PNNL` subset. Left: peptide; right, protein" width="45%" style="display: block; margin: auto;" /><img src="images\protein\corrplot\corr_pnnl.png" title="**Figure 4A-4B.** Correlation of log2FC for the `PNNL` subset. Left: peptide; right, protein" alt="**Figure 4A-4B.** Correlation of log2FC for the `PNNL` subset. Left: peptide; right, protein" width="45%" style="display: block; margin: auto;" />

To visualize the correlation of intensity data, we can use
`pepCorr_logInt` and `prnCorr_logInt` for peptide and protein data,
respectively. More details can be assessed via `?pepCorr_logFC`.

### 2.3 Heat maps

Heat map visualization is commonly applied in data sciences. The
corresponding facilities in `proteoQ` are `pepHM` and `prnHM` for
peptide and protein data, respectively. They are wrappers of
[`pheatmap`](https://cran.r-project.org/web/packages/pheatmap/pheatmap.pdf)
with modifications and exception handlings. More details can be found by
accessing the help document via `?prnHM`.

The following shows an example of protein heat map:

``` r
prnHM(
  xmin = -1, 
  xmax = 1, 
  xmargin = 0.1, 
  annot_cols = c("Group", "Color", "Alpha", "Shape"), 
  annot_colnames = c("Group", "Lab", "Batch", "WHIM"), 
  cluster_rows = TRUE, 
  cutree_rows = 10, 
  show_rownames = FALSE, 
  show_colnames = TRUE, 
  fontsize_row = 3, 
  cellwidth = 14, 
  filter_sp = exprs(species == "human"),
)
```

we chose to top annotate the heat map with the metadata that can be
found under the columns of `Group`, `Color`, `Alpha` and `Shape` in
`expt_smary.xlsx`. For better convention, we rename them to `Group`,
`Lab`, `Batch` and `WHIM` to reflect their sample characteristics. We
further supplied a vararg of `filter_sp` where we assume exclusive
interests in human proteins.

<img src="images\protein\heatmap\protein.png" title="**Figure 5A.** Heat map visualization of protein log2FC" alt="**Figure 5A.** Heat map visualization of protein log2FC" width="80%" style="display: block; margin: auto;" />

Row ordering of data is also implemented in the heat map utility.

``` r
prnHM(
  xmin = -1, 
  xmax = 1, 
  xmargin = 0.1, 
  annot_cols = c("Group", "Color", "Alpha", "Shape"), 
  annot_colnames = c("Group", "Lab", "Batch", "WHIM"), 
  cluster_rows = FALSE, 
  annot_rows = c("kin_class"), 
  show_rownames = TRUE, 
  show_colnames = TRUE, 
  fontsize_row = 2, 
  cellheight = 2, 
  cellwidth = 14, 
  filter_kin = exprs(kin_attr == TRUE, species == "human"),
  arrange_kin = exprs(kin_order, gene),
  filename = "hukin_by_class.png", 
)
```

In the above example, we applied vararg `filter_kin` to subset human
kinases from the protein data set by values under its `kin_attr` and the
`species` columns. We further row annotate the heat map with argument
`annot_rows`, which will look for values under the `kin_class` column.
With the vararg, `arrange_kin`, we supervise the row ordering of kinases
by values under the `kin_order` column and then those under the `gene`
column. Analogous to the user-supplied `filter_` arguments, the row
ordering varargs need to start with `arrange_` to indicate the task of
row ordering.

<img src="images\protein\heatmap\kinase.png" title="**Figure 5B.** Heat map visualization of kinase log2FC" alt="**Figure 5B.** Heat map visualization of kinase log2FC" width="80%" style="display: block; margin: auto;" />

### 2.4 Significance tests and volcano plot visualization

In this section, we first perform the significance analysis of protein
data. The approach of contrast fit (Chambers, J. M. Linear models, 1992;
Gordon Smyth et al., `limma`) is taken in `proteoQ`. We will first
define the contrast groups for significance tests. For this purpose, I
have devided the samples by their WHIM subtypes, laboratory locations
and batch numbers. This ends up with entries of `W2.BI.TMT1`,
`W2.BI.TMT2` etc. under the `expt_smry.xlsx::Term` column. The
interactive environment between the Excel file and the `proteoQ` tool
allows us to enter more columns of contrasts when needed. For instance,
we might also be interested in a more course comparison of
inter-laboratory differences without batch effects. The corresponding
contrasts of `W2.BI`, `W16.BI` etc. can be found under a pre-made
column, `Term_2`. Having these columns in hand, we next perform
significance tests and data visualization for protein data:

``` r
# significance tests
prnSig(
  impute_na = FALSE, 
  W2_bat = ~ Term["W2.BI.TMT2-W2.BI.TMT1", 
                  "W2.JHU.TMT2-W2.JHU.TMT1", 
                  "W2.PNNL.TMT2-W2.PNNL.TMT1"], # batches
  W2_loc = ~ Term_2["W2.BI-W2.JHU", 
                    "W2.BI-W2.PNNL", 
                    "W2.JHU-W2.PNNL"], # locations
)

# volcano plots
prnVol()
```

Note that we have informed the `prnSig` utility to look for contrasts
under columns `Term` and `Term_2`, followed by the cotrast pairs in
square brackets. Pairs of contrasts are separated by commas.

The `prnVol` utility will by default match the formulae of contrasts
with those in `prnSig`; the same is true for peptide analysis. The
following plots show the batch difference between two TMT experiments
for each of the three laboratories and the location difference between
any two laboratories.

<img src="images\protein\volcplot\batches.png" title="**Figure 6A-6B.** Volcano plots of protein log2FC. Left: between batches; right: between locations." alt="**Figure 6A-6B.** Volcano plots of protein log2FC. Left: between batches; right: between locations." width="80%" style="display: block; margin: auto auto auto 0;" /><img src="images\protein\volcplot\locations.png" title="**Figure 6A-6B.** Volcano plots of protein log2FC. Left: between batches; right: between locations." alt="**Figure 6A-6B.** Volcano plots of protein log2FC. Left: between batches; right: between locations." width="80%" style="display: block; margin: auto auto auto 0;" />

In general, the special characters of `+` and `-` in contrast terms need
to be avoided in linear modeling. However, it may be sporadically
convenient to use `A+B` to denote a combined treatment of both `A` and
`B`. In the case, we will put the term(s) containing `+` or `-` into a
pair of pointy brackets. The syntax in the following hypothetical
example will compare the effects of `A`, `B`, `A+B` and the average of
`A` and `B` to control `C`.

``` r
# note that <A + B> is one condition whereas (A + B) contains two conditions
prnSig(
  fml = ~ Term["A - C", "B - C", "<A + B> - C", "(A + B)/2 - C"],
)
```

In addition to the fixed effects shown above, significance tests with
additive random effects are also supported. Analogous to protein data,
peptide data can be analyzed and visualized with `pepSig` and `pepVol`.
More examples can be found via `?prnSig` and [Lab
3.3](###%203.3%20Random%20effects) in the document.

### 2.5 Gene sets under volcano plots

There are a handful of `R` tools for gene set enrichement analysis, such
as GSEA, GSVA, gage, to name a few. It may be intuitive as well if we
can visualize the enrichment of gene sets under the context of volcano
plots at given contrasts. Provided the richness of `R` utilities in
linear modelings, the `preoteoQ` takes a naive approach thereafter to
visualize the *asymmetricity* of protein probability *p*-values under
volcano plots. In the analysis of Gene Set Probability Asymmetricity
(`GSPA`), the significance `pVals` of proteins obtained from linear
modeling are taken, followed by the calculation of the geometric mean of
`pVals` for the groups of up- or down-regulated proteins within a gene
set, as well as the corresponding mean `log2FC`. The quotient of the two
`pVals` is then taken to represent the significance of enrichment, and
the delta of the two `log2FC` for use as the fold change of enrichment.
At the input levels, the arguments `pval_cutoff` and `logFC_cutoff`
allow us to filter out low impact genes prior to the analysis. On the
output levels, argument `gspval_cutoff` sets a threshold in gene set
significance for reporting. More details can be found from the help
document via `?prnGSPA`. Note that there is no peptide counterpart for
the enrichment analysis.

We began with the analysis of `GSPA` against enrichment terms defined in
GO and KEGG data sets:

``` r
prnGSPA(
  impute_na = FALSE,
  pval_cutoff = 5E-2,
  logFC_cutoff = log2(1.2),
  gspval_cutoff = 5E-2,
  gset_nms = c("go_sets", "kegg_sets"),
)
```

The formulae of contrasts will by default match to the those used in
`prnSig`. The species will be determined automatically from input data
and the corresponding databases will be loaded. In the above example of
pdx, databases of `GO` and `KEGG` will be loaded for both human and
mouse. If we choose to focus on human proteins, we can add a vararg
statement such as `filter_sp = exprs(species == "human")`.

We next visualize the distribution of protein `log2FC` and `pVal` within
gene sets:

``` r
gspaMap(
  show_labels = TRUE,
  pval_cutoff = 5E-3, # significance threshold for mapping
  logFC_cutoff = log2(1.2), # FC threshold for mapping
  gset_nms = c("go_sets"),
  show_sig = p,
  xco = 1.2, # position of two vertical lines for FC
  yco = 0.05, # position of a horizental line for pVal
)
```

This will produce the volcano plots of proteins under gene sets that
have passed our selection criteria. Here, we show one of the examples:

<img src="images\protein\volcplot\urogenital_system_development.png" title="**Figure 7A.** An example of volcano plots of protein log2FC under a gene set" alt="**Figure 7A.** An example of volcano plots of protein log2FC under a gene set" width="80%" style="display: block; margin: auto;" />

The names of gene sets will by default match those provided in
`prnGSPA`. Despite in the above example, we chose to plot the results
against gene sets in `GO`, not `KEGG`. More details can be accessed from
the help document via `?gspaMap`.

In addition to finding gene sets with significance, `prnGSPA` reports
the essential gene sets using a greedy set cover algorithm by
[`RcppGreedySetCover`](cran.r-project.org/web/packages/RcppGreedySetCover/RcppGreedySetCover.pdf).
The correspondance between essential and all of the gene sets are stored
in `essmap_.*.csv` files under the `Protein\GSPA` folder.

The utility in `proteoQ` for conventional GSEA analysis is `prnGSEA()`.
Details can be found via `?prnGSEA` from an R console.

### 2.6 Gene set networks

In the above section, we have plotted the enrichment of gene sets by
individual GO or KEGG terms. Depending on how much the sample groups
contrast to each other, we could have produced tens or hundreds of plots
where many of them may never get viewed. Besides, gene sets can be
redundant with overlaps to one another to varying degrees. A means to
communicate the gene set results at high levels is to present them as
hierarchical trees or grouped networks.

In this section, we will visualize the connectivity of significant gene
sets by both distance heat maps and networks. For simplicity, the heat
maps or networks will be constructed only between gene sets and
essential gene sets. As mentioned in section `Gene sets under volcano
plots`, the essential gene sets were approximated with greedy set cover.
This will reduce the dimensionality of data from \(n * n\) to \(n * m\)
(\(m \le n\)).

We next gauge the redundancy of a gene set in relative to an essential
set by counting the numbers of intersecting gene IDs. This is documented
as the `fraction` of overlap between gene sets when calling `prnGSPA`.
The values are available in output files such as
`Protein\GSPA\essmap_.*.csv`. For network visualization, the gene sets
are further classified by their distance using hierarchial clustering.

In this following, we first perform simple heat map visualization
between all significant gene sets in columns and essential groups in
rows.

``` r
prnGSPAHM(
  annot_cols = "ess_idx",
  annot_colnames = "Eset index",
  filename = "all_sets.png", 
)
```

The distance in heat is \(D = 1-f\) where \(f\) is the fraction of
overlap in IDs between two gene sets. The smaller the distance, the
greater the overlap is between two gene sets. For convenience, a
`distance` column is also made available in the `essmap_.*.csv` file.

<img src="images\protein\gspa\all_sets.png" title="**Figure 7B.** Heat map visualization of the distance between all and essential gene sets. The contrasts are defined in 'prnSig(W2_loc = )' in section 2.4 Significance tests and volcano plot visualization" alt="**Figure 7B.** Heat map visualization of the distance between all and essential gene sets. The contrasts are defined in 'prnSig(W2_loc = )' in section 2.4 Significance tests and volcano plot visualization" width="80%" style="display: block; margin: auto;" />

As expected, we saw zero overlap between human and mouse gene sets.
Within each organism, low-redundancy `red` cells overwhelm the heat map
and might have impeded us from capturing high-redudancy terms in `blue`.
We can, however, readily de-emphasize the `red` cells by data
filtration. In the example shown below, we chose to keep more redundant
terms at distances shorter than or equal to 0.33:

``` r
prnGSPAHM(
  filter_by = exprs(distance <= .33),
  filter_sp = exprs(start_with_str("hs", term)), 
  annot_cols = "ess_idx",
  annot_colnames = "Eset index",
  annot_rows = "ess_size", 
  filename = show_human_redundancy.png,
)
```

Note that there is a second `vararg` expression,
`exprs(start_with_str("hs", term))`. In this expression, we have used a
pseudoname approach to subset terms starting with character string `hs`
under the column `term` in `GSPA` result files, which corresponds to
human gene sets for both GO and KEGG.\[11\] More examples of the
pseudoname approach can be found from [Lab
3.2](###%203.2%20Data%20subsets) in this document. More examples of the
utility can be found via `?prnGSPAHM`.

<img src="images\protein\gspa\show_human_redundancy.png" title="**Figure 7C.** Heat map visualization of human gene sets at a distance cut-off 0.2" alt="**Figure 7C.** Heat map visualization of human gene sets at a distance cut-off 0.2" width="80%" style="display: block; margin: auto;" />

Aside from heat maps, `prnGSPAHM` produces the networks of gene sets via
[`networkD3`](http://christophergandrud.github.io/networkD3/), for
interactive exploration of gene set redundancy.

<img src="images\protein\gspa\gspa_connet.png" title="**Figure 7D.** Snapshots of the networks of biological terms. Left, distance &lt;= 0.8; right, distance &lt;= 0.2." alt="**Figure 7D.** Snapshots of the networks of biological terms. Left, distance &lt;= 0.8; right, distance &lt;= 0.2." width="40%" style="display: block; margin: auto;" /><img src="images\protein\gspa\gspa_redund.png" title="**Figure 7D.** Snapshots of the networks of biological terms. Left, distance &lt;= 0.8; right, distance &lt;= 0.2." alt="**Figure 7D.** Snapshots of the networks of biological terms. Left, distance &lt;= 0.8; right, distance &lt;= 0.2." width="40%" style="display: block; margin: auto;" />

### 2.7 Trend Analysis

The following performs the trend analysis against protein expressions.
More information can be found from
[`cmeans`](https://www.rdocumentation.org/packages/e1071/versions/1.7-2/topics/cmeans),
[`Mfuzz`](https://www.bioconductor.org/packages/release/bioc/vignettes/Mfuzz/inst/doc/Mfuzz.pdf)
and `?anal_prnTrend`. Note that the number of clusters is provided by
`n_clust`, which can be a single value or a vector of integers.

``` r
# soft clustering of protein expression data
anal_prnTrend(
  col_order = Order,
  n_clust = c(5:8), 
  
  filter_by_npep = exprs(prot_n_pep >= 2),
)

# visualization
plot_prnTrend(
  col_order = Order,
  n_clust = 6, 
  
  filter_by_npep = exprs(prot_n_pep >= 4),
)
```

The argument `col_order` provides a means to supervise the order of
samples in result tables or during the trend visualization. In the above
example, the `anal_prnTrend` and `plot_prnTrend` will both look into the
field under the `expt_smry.xlsx::Order` column for sample arrangement.
At `n_clust = 6`, the correspondence between protein IDs and their
cluster assignments is summarised in file `Protein_Trend_Z_n6.csv`. The
letter `Z` in the file name denotes the option of `scale_log2r = TRUE`.

<img src="images\protein\trend\prn_trend_n6.png" title="**Figure 8.** Trend analysis of protein log2FC." alt="**Figure 8.** Trend analysis of protein log2FC." width="80%" style="display: block; margin: auto auto auto 0;" />

### 2.8 NMF Analysis

The following performs the NMF analysis against protein data. More
details can be found from
[`NMF`](https://cran.r-project.org/web/packages/NMF/vignettes/NMF-vignette.pdf)
and `anal_prnNMF`.

``` r
# load library
library(NMF)

# NMF analysis
anal_prnNMF(
  impute_na = FALSE,
  col_group = Group, # optional a priori knowledge of sample groups
  r = c(5:8),
  nrun = 200, 
  filter_by_npep = exprs(prot_n_pep >= 2),
)

# consensus heat map
plot_prnNMFCon(
  impute_na = FALSE,
  annot_cols = c("Color", "Alpha", "Shape"),
  annot_colnames = c("Lab", "Batch", "WHIM"),
  width = 10,
  height = 10, 
)

# coefficient heat map
plot_prnNMFCoef(
  impute_na = FALSE,
  r = 6, 
  annot_cols = c("Color", "Alpha", "Shape"), 
  annot_colnames = c("Lab", "Batch", "WHIM"), 
  width = 10, 
  height = 10, 
)

# metagene heat map(s)
plot_metaNMF(
  impute_na = FALSE,
  r = 6, 
  annot_cols = c("Color", "Alpha", "Shape"), 
  annot_colnames = c("Lab", "Batch", "WHIM"), 
  
  fontsize = 8, 
  fontsize_col = 5,
)
```

<img src="images\protein\nmf\prn_nmf_r6_consensus.png" title="**Figure 9A-9B.** NMF analysis of protein log2FC. Left: concensus; right: coefficients." alt="**Figure 9A-9B.** NMF analysis of protein log2FC. Left: concensus; right: coefficients." width="45%" style="display: block; margin: auto auto auto 0;" /><img src="images\protein\nmf\prn_nmf_r6_coef.png" title="**Figure 9A-9B.** NMF analysis of protein log2FC. Left: concensus; right: coefficients." alt="**Figure 9A-9B.** NMF analysis of protein log2FC. Left: concensus; right: coefficients." width="45%" style="display: block; margin: auto auto auto 0;" />

### 2.9 STRING Analysis

The following performs the [`STRING`](http://www.string-db.org) analysis
of protein-protein interactions. More details can be found from
`?getStringDB`.

``` r
getStringDB(
  db_path = "~\\proteoQ\\dbs\\string",
  score_cutoff = .9,
  adjP = FALSE,
  filter_by_sp = exprs(species %in% c("human", "mouse")), 
  filter_by_npep = exprs(n_pep >= 2), 
)
```

The results of protein-protein interaction is summarised in
`Protein_STRING_ppi.tsv` and the expression data in
`Protein_STRING_expr.tsv`. The files are formatted for direct
applications with [`Cytoscape`](https://cytoscape.org). When calling
`getStringDB`, the corresponding databases will be downloaded
automatically if not yet present locally. One can also choose to
download separately the databases for a given `species`:

``` r
dl_stringdbs(
  species = rat,
  db_path = "~\\proteoQ\\dbs\\string", 
)
```

### 2.9 Missing value imputation

Imputation of peptide and protein data are handle with `pepImp` and
`prnImp`. More information can be found from
[`mice`](https://cran.r-project.org/web/packages/mice/mice.pdf) and
`?prnImp`.

## 3 Labs

### 3.1 Reference choices

In this lab, we explore the effects of reference choices on data
normalization and cleanup.

#### 3.1.1 References on data scaling

We first copy data over to the file directory specified by `temp_dir`,
followed by PSM, peptide normalization and histogram visualization of
peptide `log2FC`.

``` r
# directory setup
dir.create("C:\\The\\W2_ref\\Example", recursive = TRUE, showWarnings = FALSE)
temp_dir <- "C:\\The\\W2_ref\\Example"

# exemplary data
library(proteoQDA)
cptac_csv_1(temp_dir)
cptac_expt_ref_w2(temp_dir)
cptac_frac_1(temp_dir)

# experiment upload
library(proteoQ)
load_expts(temp_dir, expt_smry_ref_w2.xlsx)

# PSM normalization
normPSM(
  group_psm_by = pep_seq,
  group_pep_by = gene, 
  fasta = c("~\\proteoQ\\dbs\\fasta\\refseq\\refseq_hs_2013_07.fasta", 
            "~\\proteoQ\\dbs\\fasta\\refseq\\refseq_mm_2013_07.fasta"), 
  rptr_intco = 3000,
  rm_craps = TRUE,
  rm_krts = FALSE,
  rm_outliers = FALSE, 
  annot_kinases = TRUE, 
  plot_rptr_int = TRUE, 
  plot_log2FC_cv = TRUE, 
  
  filter_peps = exprs(pep_expect <= .1), 
)

# Peptide normalization
normPep(
  method_psm_pep = median, 
  method_align = MGKernel, 
  range_log2r = c(5, 95), 
  range_int = c(5, 95), 
  n_comp = 3, 
  seed = 749662, 
  maxit = 200, 
  epsilon = 1e-05, 
)

# histogram visualization
pepHist(
  scale_log2r = FALSE, 
  ncol = 9,
)
```

Notice that in the histograms the `log2FC` profiles of `WHIM2` samples
are much narrower than those of `WHIM16` (**Figure S1A**). This will
occur when a reference is more similar to one group of sample(s) than
the other. In our case, the reference is one of `WHIM2`. The difference
in the breadth of `log2FC` profiles between the `WHIM16` and the `WHIM2`
groups is likely due to the genuine difference in their proteomes. If
the above argument is valid, a scaling normalize would moderate, and
thus bias, the quantitative difference in proteomes between `WHIM2` and
`WHIM16`.

<img src="images\peptide\histogram\peptide_ref_w2.png" title="**Figure S1A.** Histograms of peptide log2FC with a WHIM2 reference." alt="**Figure S1A.** Histograms of peptide log2FC with a WHIM2 reference." width="80%" style="display: block; margin: auto;" />

We alternatively seek a “center-of-mass” representation for uses as
references. We select one `WHIM2` and one `WHIM16` from each 10-plex
TMT. The `proteoQ` tool will average the signals from designated
references. Thefore, the derived reference can be viewed as a mid point
of the `WHIM2` and the `WHIM16` proteomes. We next perform analogously
the data summary and histogram visualization.

``` r
# directory setup
dir.create("C:\\The\\W2_W16_ref\\Example", recursive = TRUE, showWarnings = FALSE)
temp_dir_2 <- "C:\\The\\W2_W16_ref\\Example"

# exemplary data
library(proteoQDA)
cptac_csv_1(temp_dir_2)
expt_smry_ref_w2_w16(temp_dir_2)
cptac_frac_1(temp_dir_2)

# experiment upload
library(proteoQ)
load_expts(temp_dir_2, expt_smry_ref_w2_w16.xlsx)

# PSM normalization
normPSM(
  group_psm_by = pep_seq,
  group_pep_by = gene, 
  fasta = c("~\\proteoQ\\dbs\\fasta\\refseq\\refseq_hs_2013_07.fasta", 
            "~\\proteoQ\\dbs\\fasta\\refseq\\refseq_mm_2013_07.fasta"), 
  rptr_intco = 3000,
  rm_craps = TRUE,
  rm_krts = FALSE,
  rm_outliers = FALSE, 
  annot_kinases = TRUE, 
  plot_rptr_int = TRUE, 
  plot_log2FC_cv = TRUE, 
  
  filter_peps = exprs(pep_expect <= .1), 
)

# peptide normalization
normPep(
    method_psm_pep = median, 
    method_align = MGKernel, 
    range_log2r = c(5, 95), 
    range_int = c(5, 95), 
    n_comp = 3, 
    seed = 749662, 
    maxit = 200, 
    epsilon = 1e-05, 
)

# histogram visualization
pepHist(
  scale_log2r = FALSE, 
  ncol = 8,
)
```

With the new reference, we have achieved `log2FC` profiles that are more
comparable in breadth between `WHIM2` and `WHIM16` samples and a
subsequent scaling normalization seems more suitable.

<img src="images\peptide\histogram\peptide_ref_w2_w16.png" title="**Figure S1B.** Histograms of peptide log2FC with a combined WHIM2 and WHIM16 reference." alt="**Figure S1B.** Histograms of peptide log2FC with a combined WHIM2 and WHIM16 reference." width="80%" style="display: block; margin: auto;" />

#### 3.1.2 References on data CV

In this section, we explore the effects of reference choices on the CV
of `log2FC`. For simplicity, we will visualize the peptide data that
link to the `BI` subset at batch number one. We first add a new column,
let’s say `BI_1`, in `expt_smry_ref_w2.xlsx` with the corresponding
samples being indicated (see also section 1.3: Renormalize data agaist
column subsets). We next display the distributions of proteins CV
measured from contributing peptides before data removals (**Figure
S1C**):

<p class="comment">

<strong>Check</strong> the presence of column `BI_1` in
`expt_smry_ref_w2.xlsx` before proceed; or update the `proteoQDA`
package.

</p>

``` r
# experiment upload
load_expts(temp_dir, expt_smry_ref_w2.xlsx)

# `BI_1` subset
purgePep(
  col_select = BI_1, 
  ymax = 1.2,
  ybreaks = .5,
  width = 8,
  height = 8,
  flip_coord = TRUE, 
  filename = BI_1.png,
)
```

Notice that the CV distributions of `WHIM2` are much narrower than those
of `WHIM16`. This makes intuitive sense given that the `log2FC` profiles
of WHIM2 are much narrows as well (**Figure S1A**). We might adjust the
CV in relative to the widths of `log2FC` profiles with `purgePep(adjSD =
TRUE, ...)`. This could help the visualization but probably not solves
directly our problem of finding low-quality data entries. One resort may
be trimming data points by percentiles:

``` r
purgePep(
  col_select = BI_1, 
  pt_cv = .95, 
  ymax = 1.2,
  ybreaks = .5,
  width = 8,
  height = 8,
  flip_coord = TRUE, 
  filename = BI_1_pt_cv.png,  
)
```

<img src="images\peptide\purge\BI_1.png" title="**Figure S1C-S1D.** Protein CV from peptide measures with WHIM2 reference. Left: before trimming; right: after trimming." alt="**Figure S1C-S1D.** Protein CV from peptide measures with WHIM2 reference. Left: before trimming; right: after trimming." width="45%" style="display: block; margin: auto auto auto 0;" /><img src="images\peptide\purge\BI_1_pt_cv.png" title="**Figure S1C-S1D.** Protein CV from peptide measures with WHIM2 reference. Left: before trimming; right: after trimming." alt="**Figure S1C-S1D.** Protein CV from peptide measures with WHIM2 reference. Left: before trimming; right: after trimming." width="45%" style="display: block; margin: auto auto auto 0;" />

### 3.2 Data subsets

In this lab, we will first apply pseudoname approaches to subset data.
The availble pesudonames include

  - `contain_str`: contain a literal string; “PEPTIDES” contain\_str
    “TIDE”.  
  - `contain_chars_in`: contain some of the characters in a literal
    string; “PEPTIDES” contain\_chars\_in “XP”.  
  - `not_contain_str`: not contain a literal string; “PEPTIDES”
    not\_contain\_str “TED”.
  - `not_contain_chars_in`: not contain any of the characters in a
    literal string; “PEPTIDES” not\_contain\_chars\_in “CAB”.  
  - `start_with_str`: start with a literal string. “PEPTIDES”
    start\_with\_str “PEP”.
  - `end_with_str`: end with a literal string. “PEPTIDES” end\_with\_str
    “TIDES”.  
  - `start_with_chars_in`: start with one of the characters in a literal
    string. “PEPTIDES” start\_with\_chars\_in “XP”.  
  - `ends_with_chars_in`: end with one of the characters in a literal
    string. “PEPTIDES” ends\_with\_chars\_in “XS”.

These functions are typically coupled to the varargs of `filter_` or
`slice_` for the subsetting of data rows based on their names. More
information can be found from the help document via `?contain_str`. In
the following example, we will apply `contain_chars_in` to subset
peptide data.

The CPTAC publication contains both global and phosphopeptide data from
the same samples. This allows us to explore the stoichiometry of
phosphopeptide subsets in relative to the combined data sets of `global
+ phospho` peptides. We first performed a search against the combined
data. The search results are available in `proteoQDA`. We next copy the
result files over, followed by the analysis and visualization of the
`BI` subset:

``` r
# directory setup
dir.create("C:\\The\\Phosphopeptide\\Example", recursive = TRUE, showWarnings = FALSE)
temp_phospho_dir <- "C:\\The\\Phosphopeptide\\Example"

# exemplary data
library(proteoQDA)
cptac_csv_2(temp_phospho_dir)
cptac_expt_2(temp_phospho_dir)
cptac_frac_2(temp_phospho_dir)

# experiment upload
library(proteoQ)
load_expts(temp_phospho_dir, expt_smry.xlsx)

# PSM normalization
# note that `group_psm_by = pep_seq_mod` 
normPSM(
  group_psm_by = pep_seq_mod,
  group_pep_by = gene, 
  fasta = c("~\\proteoQ\\dbs\\fasta\\refseq\\refseq_hs_2013_07.fasta", 
            "~\\proteoQ\\dbs\\fasta\\refseq\\refseq_mm_2013_07.fasta"), 
  rptr_intco = 3000,
  rm_craps = TRUE,
  rm_krts = FALSE,
  rm_outliers = FALSE, 
  annot_kinases = TRUE, 
  plot_rptr_int = TRUE, 
  plot_log2FC_cv = TRUE, 
  
  filter_peps = exprs(pep_expect <= .1), 
)

# peptide normalization
normPep(
  method_psm_pep = median, 
  method_align = MGKernel, 
  range_log2r = c(5, 95), 
  range_int = c(5, 95), 
  n_comp = 3, 
  seed = 749662, 
  maxit = 200, 
  epsilon = 1e-05, 
)

# (a) phospho subsets without y-scaling
pepHist(
  col_select = BI, 
  scale_log2r = TRUE, 
  filter_peps = exprs(contain_chars_in("sty", pep_seq_mod)), 
  scale_y = FALSE, 
  ncol = 4, 
  filename = "BI_pSTY_scaley_no.png",
)

# (b) phospho subsets with y-scaling
pepHist(
  col_select = BI, 
  scale_log2r = TRUE, 
  filter_peps = exprs(contain_chars_in("sty", pep_seq_mod)), 
  scale_y = TRUE, 
  ncol = 4, 
  filename = "BI_pSTY_scaley_yes.png",
)
```

Note that we have applied the new grammer of `contain_chars_in("sty",
pep_seq_mod)` to extract character strings containing lower-case letters
‘s’, ‘t’ or ‘y’ under the `pep_seq_mod` column in `Peptide.txt`. This
corresponds to the subsettting of peptides with phosphorylation(s) in
serine, thereonine or tyrosine.\[12\]

<img src="images\peptide\histogram\bi_phospho_scaley_no.png" title="**Figure S2A-S2B.** Histograms of log2FC. Left: phosphopeptides without y-axix scaling; right: phosphopeptides with y-axix scaling. The density curves are from the combined data of global + phospho." alt="**Figure S2A-S2B.** Histograms of log2FC. Left: phosphopeptides without y-axix scaling; right: phosphopeptides with y-axix scaling. The density curves are from the combined data of global + phospho." width="45%" style="display: block; margin: auto auto auto 0;" /><img src="images\peptide\histogram\bi_phospho_scaley_yes.png" title="**Figure S2A-S2B.** Histograms of log2FC. Left: phosphopeptides without y-axix scaling; right: phosphopeptides with y-axix scaling. The density curves are from the combined data of global + phospho." alt="**Figure S2A-S2B.** Histograms of log2FC. Left: phosphopeptides without y-axix scaling; right: phosphopeptides with y-axix scaling. The density curves are from the combined data of global + phospho." width="45%" style="display: block; margin: auto auto auto 0;" />

Ideally, the profiles of the `log2FC` between the `phospho` subsets and
the overall data would either align at the maximum density or perhaps
offset by similar distance among replicated samples. In this example,
the alginment at maximum density seems to be the case. The observation
raises the possibility of measuring the stoichiometry of
phosphoproteomes in relative to global data across sample types or
conditions.

In addition to pseudonames, convenience columns such as
`pep_mod_protntac` and `pep_mod_sty` are made available in
`Peptide.txt`, to indicate the property of peptide modifications of
protein N-terminal acetylation and phosphorylation, respectively. We can
use alternatively the column keys to subset data, for example,
extracting peptides from N-terminal acetylated proteins:

``` r
# (c) N-term acetylation subsets without y-scaling
pepHist(
  col_select = BI, 
  scale_log2r = TRUE, 
  filter_peps = exprs(pep_mod_protntac == TRUE), 
  scale_y = FALSE, 
  ncol = 4, 
  filename = "BI_NAc_scaley_no.png",
)

# (d) N-term acetylation subsets with y-scaling
pepHist(
  col_select = BI, 
  scale_log2r = TRUE, 
  filter_peps = exprs(pep_mod_protntac), 
  scale_y = TRUE, 
  ncol = 4, 
  filename = "BI_NAc_scaley_yes.png",
)
```

<img src="images\peptide\histogram\bi_nac_scaley_no.png" title="**Figure S2C-S2D.** Histograms of the log2FC of peptides from N-terminal acetylated proteins. Left:  without y-axix scaling; right: with y-axix scaling." alt="**Figure S2C-S2D.** Histograms of the log2FC of peptides from N-terminal acetylated proteins. Left:  without y-axix scaling; right: with y-axix scaling." width="45%" style="display: block; margin: auto auto auto 0;" /><img src="images\peptide\histogram\bi_nac_scaley_yes.png" title="**Figure S2C-S2D.** Histograms of the log2FC of peptides from N-terminal acetylated proteins. Left:  without y-axix scaling; right: with y-axix scaling." alt="**Figure S2C-S2D.** Histograms of the log2FC of peptides from N-terminal acetylated proteins. Left:  without y-axix scaling; right: with y-axix scaling." width="45%" style="display: block; margin: auto auto auto 0;" />

Pseudonames and convience columns can be used interexchangeably for
simple conditions. In the following example, we assume that peptide
sequences are under the column `pep_seq_mod` in `Peptide.txt` with
variably modified residues in lower case. we can exclude oxidized
methione or deamidated asparagine from uses in data normalization:

``` r
normPrn(
  method_pep_prn = median, 
  method_align = MGKernel, 
  range_log2r = c(5, 95), 
  range_int = c(5, 95), 
  n_comp = 2, 
  seed = 749662, 
  maxit = 200, 
  epsilon = 1e-05, 
  slice_by_mn = exprs(not_contain_chars_in("mn", pep_seq_mod)),
)
```

or use alternatively the convience columns, `pep_mod_m` and `pep_mod_n`,
for the same purpose:

``` r
normPrn(
  method_pep_prn = median, 
  method_align = MGKernel, 
  range_log2r = c(5, 95), 
  range_int = c(5, 95), 
  n_comp = 2, 
  seed = 749662, 
  maxit = 200, 
  epsilon = 1e-05, 
  slice_by_mn = exprs(pep_mod_m == FALSE, pep_mod_n == FALSE),
)
```

### 3.3 Random effects

Models that incorporate both fixed- and random-effects terms in a linear
predictor expression are often termed mixed effects models.

#### 3.3.1 Single random effect

In proteomic studies involved multiple multiplex `TMT` experiments, the
limited multiplicity of isobaric tags requires sample parting into
subgroups. Measures in `log2FC` are then obtained within each subgroup
by comparing to common reference materials, followed by data bridging
across experiments. This setup violates the independence assumption in
statistical sampling as the measures of `log2FC` are batched by `TMT`
experiments. In this lab, we will use the CPTAC data to test the
statistical significance in protein abundance between the `WHIM2` and
the `WHIM16` subtypes, by first taking the batch effects into account.
We will use mixed-effects models to explore the random effects that were
introduced by the data stitching. In case that you would like to find
out more about mixed-effects models in R, I found the online
[tutorial](http://www.bodowinter.com/tutorial/bw_LME_tutorial2.pdf) a
helpful resource.

We start off by copying over the `expt_smry.xlsx` file, which contains a
newly created column, `Term_3`, for terms to be used in the statistical
tests of `WHIM2` and `WHIM16`. We also copy over the protein results
from `Section 1` of the vignette and carry out the signficance tests
with and without random effects.

``` r
# directory setup
dir.create("C:\\The\\Random_effects\\Example", recursive = TRUE, showWarnings = FALSE)
temp_raneff_dir <- "C:\\The\\Random_effects\\Example"

# exemplary data
library(proteoQDA)
cptac_prn_1(temp_raneff_dir)
cptac_expt_3(temp_raneff_dir)
cptac_frac_3(temp_raneff_dir)

# experiment upload
library(proteoQ)
load_expts(temp_raneff_dir, expt_smry.xlsx)

# protein significance tests
prnSig(
  impute_na = FALSE, 
  W2_vs_W16_fix = ~ Term_3["W16-W2"], # fixed effect only
  W2_vs_W16_mix = ~ Term_3["W16-W2"] + (1|TMT_Set), # one fixed and one random effects
)

# volcano plots
prnVol()
```

In the formula linked to argument `W2_vs_W16_mix`, the random effect
`(1|TMT_Set)` is an addition to the fix effect `Term_3["W16-W2"]`. The
syntax `(1|TMT_Set)` indicates the `TMT_Set` term to be parsed as a
random effect. The name of the term is again a column key in
`expt_smry.xlsx`. In this example, the `TMT` batches are documented
under the column `TMT_Set` and can be applied directly to our formula.
Upon the completion of the protein signficance tests, we can analyze
analogously the gene set enrichment against these new formulas by
calling functions `prnGSPA` and `gspaMAP`.

#### 3.3.2 Multiple random effects

In this section, we will test the statistical significance in protein
abundance changes between the `WHIM2` and the `WHIM16` subtypes, by
taking additively both the TMT batch effects and the laboratory effects
into account. At the time of writing the document, I don’t yet know how
to handle multiple random effects using `limma`. Alternatively, I use
`lmerTest` to do the work.

Missing values can frequently fail random-effects modeling with more
complex error structures and need additional cares. One workaround is to
simply restrict ourselves to entries that are complete in cases. This
would lead to a number of proteins not measurable in their statistical
significance. Alternatively, we may seek to fill in missing values using
techniques such as multivariate imputation.

We further note that the laboratory differences are coded under columns
`Color` in `expt_smry.xlsx`. We then test the statistical difference
between `WHIM2` and `WHIM16` against the following three models:

``` r
# impute NA
prnImp(m = 5, maxit = 5)

# significance tests
prnSig(
  impute_na = TRUE, # otherwise coerce to complete cases 
  method = lm,
  W2_vs_W16_fix = ~ Term_3["W16-W2"], # one fixed effect
  W2_vs_W16_mix = ~ Term_3["W16-W2"] + (1|TMT_Set), # one fixed and one random effect
  W2_vs_W16_mix_2 = ~ Term_3["W16-W2"] + (1|TMT_Set) + (1|Color), # one fixed and two random effects
)

# correlation plots
read.csv(file.path(temp_raneff_dir, "Protein\\Model\\Protein_pVals.txt"), 
         check.names = FALSE, header = TRUE, sep = "\t") %>%
  dplyr::select(grep("pVal\\s+", names(.))) %>% 
  `colnames<-`(c("none", "one", "two")) %>% 
  dplyr::mutate_all(~ -log10(.x)) %>% 
  GGally::ggpairs(columnLabels = as.character(names(.)), labeller = label_wrap_gen(10), title = "", 
    xlab = expression("pVal ("*-log[10]*")"), ylab = expression("pVal ("*-log[10]*")")) 
```

The correlation plots indicate that the random effects of batches and
laboratory locations are much smaller than the fixed effect of the
biological differences of `WHIM2` and `WHIM16`.

<img src="images\protein\model\raneff_models.png" title="**Figure S3.** Pearson r of protein significance p-values." alt="**Figure S3.** Pearson r of protein significance p-values." width="40%" style="display: block; margin: auto;" />

## 4 Column keys

### 4.1 Mascot

The results are reported at the levels of PSMs, peptides and proteins.
The order of column keys can vary slightly provided different databases
or accession types.

#### 4.1.1 PSMs

PSMs are reported at the basis of per TMT experiment per series of LC/MS
data acquisition. The names of the result files are
`TMTset1_LCMSinj1_PSM_N.txt`, `TMTset2_LCMSinj1_PSM_N.txt` et al. with
the indeces of TMT experiment and LC/MS injection index being indicated
in the names. The column keys are described in [`Matrix
Science`](http://www.matrixscience.com/help/csv_headers.html) with the
following additions or modifications:

| Header                | Descrption                                                                                                                                                                         | Note                                                                                                                                                                                                    |
| :-------------------- | :--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| prot\_hit\_num        | Ordinal number of the protein hit (or protein family when grouping enabled)                                                                                                        | Mascot                                                                                                                                                                                                  |
| prot\_family\_member  | Ordinal number of the protein family member when grouping enabled                                                                                                                  | Mascot                                                                                                                                                                                                  |
| prot\_acc             | Protein accession string                                                                                                                                                           | Mascot                                                                                                                                                                                                  |
| prot\_desc            | Protein description taken from Fasta title line                                                                                                                                    | Mascot                                                                                                                                                                                                  |
| prot\_score           | Protein Mascot score                                                                                                                                                               | Mascot                                                                                                                                                                                                  |
| prot\_mass            | Protein mass                                                                                                                                                                       | Mascot                                                                                                                                                                                                  |
| prot\_matches         | Count of PSMs                                                                                                                                                                      | Mascot                                                                                                                                                                                                  |
| prot\_matches\_sig    | Count of PSMs that have significant scores under a proposed protein                                                                                                                | Joint Mascot `prot_matches_sig` from individual data sources; PSMs with void reporter-ion intensity are included.                                                                                       |
| prot\_sequences       | Count of distinct sequences                                                                                                                                                        | Mascot                                                                                                                                                                                                  |
| prot\_sequences\_sig  | Count of distinct sequences that have significant scores under a proposed protein                                                                                                  | Joint Mascot `prot_sequences_sig` from individual data sources; the counts may be greater than `prot_sequences` when peptides with different variable modifications are treated as different identities |
| prot\_len             | The number of amino acid residues under a proposed protein                                                                                                                         | Mascot; or proteoQ if absent from Mascot PSM exports                                                                                                                                                    |
| prot\_cover           | Protein sequence coverage                                                                                                                                                          | Calculated from the union of individual data sources                                                                                                                                                    |
| prot\_…               | Additional protein keys from Mascot PSM exports                                                                                                                                    | By users                                                                                                                                                                                                |
| prot\_n\_psm          | Count of significant PSMs in quantitation under a proposed protein                                                                                                                 | By each TMT experiment and LC/MS series; the counts exclude entries that are void in reporter-ion intensity or filtered by users                                                                        |
| prot\_n\_pep          | Count of significant peptide sequences in quantitation under a proposed protein                                                                                                    | Cf. `prot_n_psm`                                                                                                                                                                                        |
| pep\_seq\_mod         | pep\_seq with variable modifications in the lower cases                                                                                                                            | E.g. “-.\_mAsGVAVSDGVIK.V” with a methionine oxidation and a serine phosphorylation                                                                                                                     |
| pep\_query            | Ordinal number of query after sorting by Mr                                                                                                                                        | Mascot                                                                                                                                                                                                  |
| pep\_rank             | Peptide sequence match (PSM) rank. If two PSMs have same score they have the same rank.                                                                                            | Mascot                                                                                                                                                                                                  |
| pep\_isbold           | If grouping enabled, then a significant PSM. Otherwise, indicates this is the highest scoring protein that contains a match to this query.                                         | Mascot                                                                                                                                                                                                  |
| pep\_isunique         | Peptide sequence is unique to hit (grouping off) or family member (grouping on)                                                                                                    | Mascot                                                                                                                                                                                                  |
| pep\_exp\_mz          | Observed or experimental m/z value                                                                                                                                                 | Mascot                                                                                                                                                                                                  |
| pep\_exp\_mr          | Molecular mass calculated from experimental m/z value                                                                                                                              | Mascot                                                                                                                                                                                                  |
| pep\_exp\_z           | Observed or experimental charge                                                                                                                                                    | Mascot                                                                                                                                                                                                  |
| pep\_calc\_mr         | Molecular mass calculated from matched peptide sequence                                                                                                                            | Mascot                                                                                                                                                                                                  |
| pep\_delta            | pep\_exp\_mr – pep\_calc\_mr                                                                                                                                                       | Mascot                                                                                                                                                                                                  |
| pep\_start            | Ordinal position of first peptide residue in protein sequence                                                                                                                      | Cf. `prot_len`                                                                                                                                                                                          |
| pep\_end              | Ordinal position of last peptide residue in protein sequence                                                                                                                       | Cf. `prot_len`                                                                                                                                                                                          |
| pep\_miss             | Count of missed cleavage sites in peptide                                                                                                                                          | Mascot                                                                                                                                                                                                  |
| pep\_score            | Mascot score for PSM                                                                                                                                                               | Mascot                                                                                                                                                                                                  |
| pep\_expect           | Expectation value for PSM                                                                                                                                                          | Mascot                                                                                                                                                                                                  |
| pep\_res\_before      | Flanking residue on N-term side of peptide                                                                                                                                         | Mascot                                                                                                                                                                                                  |
| pep\_seq              | One-letter representation of peptide sequences                                                                                                                                     | The acetylations of protein N-terminals is indicated by ’\_’ and the flanking residues on the N- or C-terminal side of peptides separated by ‘.’, e.g. “-.\_MASGVAVSDGVIK.V”                            |
| pep\_res\_after       | Flanking residue on C-term side of peptide                                                                                                                                         | Mascot                                                                                                                                                                                                  |
| pep\_var\_mod         | Variable modifications from all sources as list of names                                                                                                                           | Mascot                                                                                                                                                                                                  |
| pep\_var\_mod\_pos    | Variable modifications as a string of digits, e.g. ’0.0001000.0?. Non-zero digits identify mods according to key in export header. First and last positions are for terminus mods. | Mascot                                                                                                                                                                                                  |
| pep\_summed\_mod\_pos | When two variable modifications occur at the same site, a string of digits defining the second mod                                                                                 | Mascot                                                                                                                                                                                                  |
| pep\_local\_mod\_pos  | Query-level variable modifications as a string of digits. The names of the mods will be listed in pep\_var\_mod                                                                    | Mascot                                                                                                                                                                                                  |
| pep\_scan\_title      | Scan title taken from peak list                                                                                                                                                    | Mascot                                                                                                                                                                                                  |
| pep\_…                | Additional peptide keys from Mascot PSM exports                                                                                                                                    | By users                                                                                                                                                                                                |
| pep\_n\_psm           | Counts of significant PSMs in quantitation under a proposed peptide                                                                                                                | Cf. `prot_n_psm`                                                                                                                                                                                        |
| raw\_file             | MS file name(s) where peptides or proteins are identified                                                                                                                          |                                                                                                                                                                                                         |
| gene                  | Protein gene name                                                                                                                                                                  |                                                                                                                                                                                                         |
| acc\_type             | The type of accession names                                                                                                                                                        | One of `refseq_acc`, `uniprot_acc` or `uniprot_id`                                                                                                                                                      |
| uniprot\_id           | Uniprot ID                                                                                                                                                                         | Optional for UniProt Fasta; the key will become `uniprot_acc` if the primary one is `uniprot_id`                                                                                                        |
| species               | The species of a protein entry                                                                                                                                                     |                                                                                                                                                                                                         |
| entrez                | Protein Entrez ID                                                                                                                                                                  |                                                                                                                                                                                                         |
| kin\_attr             | The attribute of proteins being kinases                                                                                                                                            | Optional at `normPSM(annot_kinases = TRUE, ...)`                                                                                                                                                        |
| kin\_class            | The classes of kinases, e.g., TK, TKL…                                                                                                                                             | Cf. `kin_attr`                                                                                                                                                                                          |
| kin\_order            | The order of “kin\_class” from the kinase tree diagram                                                                                                                             | Cf. `kin_attr`                                                                                                                                                                                          |
| is\_tryptic           | Logical indicating if a sequence belongs to a canonical tryptic peptide                                                                                                            | Optional when `pep_start` and `pep_end` are absent from Mascot PSMs                                                                                                                                     |
| I126 et al.           | Reporter-ion intensity from MS/MS ion search                                                                                                                                       | Mascot                                                                                                                                                                                                  |
| N\_I126 et al.        | Normalized reporter-ion intensity                                                                                                                                                  | The calibration factors for the alignment of log2FC are used to scale the reporter-ion intensity                                                                                                        |
| sd\_log2\_R126 et al. | Standard deviation of peptide log2FC                                                                                                                                               | Calculated from contributing PSMs under each TMT channel                                                                                                                                                |
| R126 et al.           | Linear FC relative to TMT-126                                                                                                                                                      |                                                                                                                                                                                                         |
| log2\_R126 et al.     | log2FC relative to TMT-126                                                                                                                                                         |                                                                                                                                                                                                         |
| N\_log2\_R126 et al.  | Median-centered log2FC relative to TMT-126                                                                                                                                         |                                                                                                                                                                                                         |

#### 4.1.2 Peptides

Prior to significance tests, the primary peptide outputs with and
without the imputation of NA values are summarized in `Peptide.txt` and
`Peptide_impNA.txt`, respectively. The column keys therein are described
in the following:

| Header               | Descrption                                                                                                                                 | Note                                                                                                                              |
| :------------------- | :----------------------------------------------------------------------------------------------------------------------------------------- | :-------------------------------------------------------------------------------------------------------------------------------- |
| prot\_acc            | Protein accession string                                                                                                                   | Mascot                                                                                                                            |
| prot\_desc           | Protein description taken from Fasta title line                                                                                            | Mascot                                                                                                                            |
| prot\_mass           | Protein mass                                                                                                                               | Mascot                                                                                                                            |
| prot\_matches\_sig   | Count of PSMs that have significant scores under a proposed protein                                                                        | Cf. PSM keys                                                                                                                      |
| prot\_sequences\_sig | Count of distinct sequences that have significant scores under a proposed protein                                                          | Cf. PSM keys                                                                                                                      |
| prot\_len            | The number of amino acid residues under a proposed protein                                                                                 | Cf. PSM keys                                                                                                                      |
| prot\_cover          | Protein sequence coverage                                                                                                                  | Cf. PSM keys                                                                                                                      |
| prot\_n\_psm         | Count of significant PSMs in quantitation under a proposed protein                                                                         | Joint results from individual PSM tables; the counts exclude entries that are void in reporter-ion intensity or filtered by users |
| prot\_n\_pep         | Count of significant peptide sequences in quantitation under a proposed protein                                                            | Cf. `prot_n_psm`                                                                                                                  |
| pep\_seq             | One-letter representation of peptide sequences                                                                                             | Cf. PSM keys; the key will become `pep_seq_mod` at `normPSM(group_psm_by = pep_seq_mod)`                                          |
| pep\_seq\_mod        | pep\_seq with variable modifications in the lower cases                                                                                    | Cf. PSM keys; the key will become `pep_seq` at `normPSM(group_psm_by = pep_seq)`                                                  |
| pep\_n\_psm          | Counts of significant PSMs in quantitation under a proposed peptide                                                                        | Cf. `prot_n_psm`                                                                                                                  |
| pep\_isunique        | Peptide sequence is unique to hit (grouping off) or family member (grouping on)                                                            | Mascot                                                                                                                            |
| pep\_calc\_mr        | Molecular mass calculated from matched peptide sequence                                                                                    | Mascot                                                                                                                            |
| pep\_start           | Ordinal position of first peptide residue in protein sequence                                                                              | Mascot; or proteoQ if absent from Mascot PSM exports                                                                              |
| pep\_end             | Mascot: ordinal position of last peptide residue in protein sequence                                                                       | Cf. `pep_start`                                                                                                                   |
| pep\_miss            | Count of missed cleavage sites in peptide                                                                                                  | Mascot                                                                                                                            |
| pep\_rank            | Peptide sequence match (PSM) rank. If two PSMs have same score they have the same rank.                                                    | Median description from PSMs                                                                                                      |
| pep\_isbold          | If grouping enabled, then a significant PSM; otherwise, indicates this is the highest scoring protein that contains a match to this query. | Cf. `pep_rank`                                                                                                                    |
| pep\_exp\_mz         | Observed or experimental m/z value                                                                                                         | Cf. `pep_rank`                                                                                                                    |
| pep\_exp\_mr         | Molecular mass calculated from experimental m/z value                                                                                      | Cf. `pep_rank`                                                                                                                    |
| pep\_exp\_z          | Observed or experimental charge                                                                                                            | Cf. `pep_rank`                                                                                                                    |
| pep\_delta           | pep\_exp\_mr – pep\_calc\_mr                                                                                                               | Cf. `pep_rank`                                                                                                                    |
| pep\_score           | Mascot score for PSM                                                                                                                       | Cf. `pep_rank`                                                                                                                    |
| pep\_expect          | Expectation value for PSM                                                                                                                  | Geometric-mean description from PSMs                                                                                              |
| gene                 | Protein gene name                                                                                                                          |                                                                                                                                   |
| acc\_type            | The type of accession names                                                                                                                |                                                                                                                                   |
| uniprot\_id          | Uniprot ID                                                                                                                                 | Cf. PSM keys                                                                                                                      |
| entrez               | Protein Entrez ID                                                                                                                          |                                                                                                                                   |
| species              | The species of a protein entry                                                                                                             |                                                                                                                                   |
| kin\_attr            | The attribute of proteins being kinases                                                                                                    | Cf. PSM keys                                                                                                                      |
| kin\_class           | The classes of kinases, e.g., TK, TKL…                                                                                                     | Cf. PSM keys                                                                                                                      |
| kin\_order           | The order of “kin\_class” from the kinase tree diagram                                                                                     | Cf. PSM keys                                                                                                                      |
| is\_tryptic          | Logical indicating if a sequence belongs to a canonical tryptic peptide                                                                    | Cf. PSM keys                                                                                                                      |
| I… (…)               | Reporter-ion intensity                                                                                                                     | Calculated from the descriptive statistics by `method_psm_pep` in `normPep()` for indicated samples                               |
| N\_I… (…)            | Normalized I… (…)                                                                                                                          | The calibration factors for the alignment of log2FC are used to scale the reporter-ion intensity                                  |
| sd\_log2\_R (…)      | Standard deviation of protein log2FC                                                                                                       | Calculated from contributing peptides under each sample                                                                           |
| log2\_R (…)          | log2FC relative to reference materials for indicated samples                                                                               | Before normalization                                                                                                              |
| N\_log2\_R (…)       | Aligned log2\_R (…) according to method\_align in normPep() without scaling normalization                                                  |                                                                                                                                   |
| Z\_log2\_R (…)       | N\_log2\_R (…) with scaling normalization                                                                                                  |                                                                                                                                   |

#### 4.1.3 Proteins

Prior to significance tests, the primary protein outputs with and
without the imputation of NA values are summarized in `Protein.txt` and
`Protein_impNA.txt`, respectively. The corresponding column keys are
described in the following:

| Header               | Descrption                                                                                | Note                                                                                                |
| :------------------- | :---------------------------------------------------------------------------------------- | :-------------------------------------------------------------------------------------------------- |
| gene                 | Protein gene name                                                                         |                                                                                                     |
| prot\_cover          | Protein sequence coverage                                                                 | Cf. PSM keys                                                                                        |
| prot\_acc            | Protein accession string                                                                  | Mascot                                                                                              |
| prot\_desc           | Protein description taken from Fasta title line                                           | Mascot                                                                                              |
| prot\_mass           | Protein mass                                                                              | Mascot                                                                                              |
| prot\_matches\_sig   | Count of PSMs that have significant scores under a proposed protein                       | Cf. PSM keys                                                                                        |
| prot\_sequences\_sig | Count of distinct sequences that have significant scores under a proposed protein         | Cf. PSM keys                                                                                        |
| prot\_len            | The number of amino acid residues under a proposed protein                                | Cf. PSM keys                                                                                        |
| prot\_n\_psm         | Count of significant PSMs in quantitation under a proposed protein                        | Cf. Peptide keys                                                                                    |
| prot\_n\_pep         | Count of significant peptide sequences in quantitation under a proposed protein           | Cf. Peptide keys                                                                                    |
| acc\_type            | The type of accession names                                                               |                                                                                                     |
| uniprot\_id          | Uniprot ID                                                                                | Cf. PSM keys                                                                                        |
| entrez               | Protein Entrez ID                                                                         |                                                                                                     |
| species              | The species of a protein entry                                                            |                                                                                                     |
| kin\_attr            | The attribute of proteins being kinases                                                   | Cf. PSM keys                                                                                        |
| kin\_class           | The classes of kinases, e.g., TK, TKL…                                                    | Cf. PSM keys                                                                                        |
| kin\_order           | The order of “kin\_class” from the kinase tree diagram                                    | Cf. PSM keys                                                                                        |
| I… (…)               | Reporter-ion intensity                                                                    | Calculated from the descriptive statistics by `method_pep_prn` in `normPrn()` for indicated samples |
| N\_I… (…)            | Normalized I… (…)                                                                         | Cf. Peptide keys                                                                                    |
| log2\_R (…)          | log2FC relative to reference materials for indicated samples                              | Cf. Peptide keys                                                                                    |
| N\_log2\_R (…)       | Aligned log2\_R (…) according to method\_align in normPrn() without scaling normalization |                                                                                                     |
| Z\_log2\_R (…)       | N\_log2\_R (…) with scaling normalization                                                 |                                                                                                     |

### 4.2 MaxQuant

MaxQuant files shares the same folder structure as those of Mascot.

#### 4.2.1 PSMs

The column keys are defined in
[`MaxQuant`](http://www.coxdocs.org/doku.php?id=maxquant:table:msmstable)
with the following additions or modifications:

| Header                | Descrption                                                                      | Note                                                                                                                                                                         |
| :-------------------- | :------------------------------------------------------------------------------ | :--------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| prot\_acc             | Protein accession string                                                        | `Proteins` in MaxQuant                                                                                                                                                       |
| prot\_desc            | Protein description taken from Fasta title line                                 |                                                                                                                                                                              |
| prot\_mass            | Protein mass                                                                    |                                                                                                                                                                              |
| prot\_len             | The number of amino acid residues under a proposed protein                      |                                                                                                                                                                              |
| prot\_cover           | Protein sequence coverage                                                       | Calculated from the union of individual data sources                                                                                                                         |
| prot\_n\_psm          | Count of significant PSMs in quantitation under a proposed protein              | By each TMT experiment and LC/MS series; the counts exclude entries that are void in reporter-ion intensity or filtered by users                                             |
| prot\_n\_pep          | Count of significant peptide sequences in quantitation under a proposed protein | Cf. `prot_n_psm`                                                                                                                                                             |
| pep\_seq              | One-letter representation of peptide sequences                                  | The acetylations of protein N-terminals is indicated by ’\_’ and the flanking residues on the N- or C-terminal side of peptides separated by ‘.’, e.g. “-.\_MASGVAVSDGVIK.V” |
| pep\_seq\_mod         | pep\_seq with variable modifications in the lower cases                         | E.g. “-.\_mAsGVAVSDGVIK.V” with a methionine oxidation and a serine phosphorylation                                                                                          |
| pep\_isunique         | Peptide sequence is unique at the levels of protein groups, protein IDs or none | Cf. proteoQ help document via `?normPSM`                                                                                                                                     |
| pep\_res\_before      | Flanking residue on N-term side of peptide                                      |                                                                                                                                                                              |
| pep\_start            | Ordinal position of first peptide residue in protein sequence                   |                                                                                                                                                                              |
| pep\_end              | Ordinal position of last peptide residue in protein sequence                    |                                                                                                                                                                              |
| pep\_res\_after       | Flanking residue on C-term side of peptide                                      |                                                                                                                                                                              |
| pep\_n\_psm           | Counts of significant PSMs in quantitation under a proposed peptide             | Cf. `prot_n_psm`                                                                                                                                                             |
| raw\_file             | MS file name(s) where peptides or proteins are identified                       |                                                                                                                                                                              |
| m/z                   | The mass-over-charge of the precursor ion.                                      | From MaxQuant                                                                                                                                                                |
| acc\_type             | The type of accession names                                                     | One of `refseq_acc`, `uniprot_acc` or `uniprot_id`                                                                                                                           |
| uniprot\_id           | Uniprot ID                                                                      | Optional for UniProt Fasta; the key will become `uniprot_acc` if the primary one is `uniprot_id`                                                                             |
| entrez                | Protein Entrez ID                                                               |                                                                                                                                                                              |
| gene                  | Protein gene name                                                               |                                                                                                                                                                              |
| species               | The species of a protein entry                                                  |                                                                                                                                                                              |
| kin\_attr             | The attribute of proteins being kinases                                         | Optional at `normPSM(annot_kinases = TRUE, ...)`                                                                                                                             |
| kin\_class            | The classes of kinases, e.g., TK, TKL…                                          | Cf. `kin_attr`                                                                                                                                                               |
| kin\_order            | The order of “kin\_class” from the kinase tree diagram                          | Cf. `kin_attr`                                                                                                                                                               |
| is\_tryptic           | Logical indicating if a sequence belongs to a canonical tryptic peptide         |                                                                                                                                                                              |
| …                     | More column keys from MaxQuant                                                  | Cf. <http://www.coxdocs.org/doku.php?id=maxquant:table:msmstable>                                                                                                            |
| I126 et al.           | Reporter-ion intensity                                                          | Corrected or uncorrected from MaxQuant; c.f. `?normPSM`                                                                                                                      |
| N\_I126 et al.        | Normalized reporter-ion intensity                                               | The calibration factors for the alignment of log2FC are used to scale the reporter-ion intensity                                                                             |
| sd\_log2\_R126 et al. | Standard deviation of peptide log2FC                                            | Calculated from contributing PSMs under each TMT channel                                                                                                                     |
| R126 et al.           | Linear FC relative to TMT-126                                                   |                                                                                                                                                                              |
| log2\_R126 et al.     | log2FC relative to TMT-126                                                      |                                                                                                                                                                              |
| N\_log2\_R126 et al.  | Median-centered log2FC relative to TMT-126                                      |                                                                                                                                                                              |

#### 4.2.2 Peptides

The column keys in peptide tables are described below:

| Header          | Descrption                                                                                | Note                                                                                                                                                                                                                                                                                |
| :-------------- | :---------------------------------------------------------------------------------------- | :---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| prot\_acc       | Protein accession string                                                                  | Cf. PSM keys                                                                                                                                                                                                                                                                        |
| prot\_desc      | Protein description taken from Fasta title line                                           |                                                                                                                                                                                                                                                                                     |
| prot\_mass      | Protein mass                                                                              |                                                                                                                                                                                                                                                                                     |
| prot\_len       | The number of amino acid residues under a proposed protein                                |                                                                                                                                                                                                                                                                                     |
| prot\_cover     | Protein sequence coverage                                                                 | Cf. PSM keys                                                                                                                                                                                                                                                                        |
| prot\_n\_psm    | Count of significant PSMs in quantitation under a proposed protein                        | Joint results from individual PSM tables; the counts exclude entries that are void in reporter-ion intensity or filtered by users                                                                                                                                                   |
| prot\_n\_pep    | Count of significant peptide sequences in quantitation under a proposed protein           | Cf. `prot_n_psm`                                                                                                                                                                                                                                                                    |
| pep\_seq        | One-letter representation of peptide sequences                                            | Cf. PSM keys; the key will become `pep_seq_mod` at `normPSM(group_psm_by = pep_seq_mod)`                                                                                                                                                                                            |
| pep\_seq\_mod   | pep\_seq with variable modifications in the lower cases                                   | Cf. PSM keys; the key will become `pep_seq` at `normPSM(group_psm_by = pep_seq)`                                                                                                                                                                                                    |
| pep\_n\_psm     | Counts of significant PSMs in quantitation under a proposed peptide                       | Cf. `prot_n_psm`                                                                                                                                                                                                                                                                    |
| pep\_isunique   | Peptide sequence is unique at the levels of protein groups, protein IDs or none           | Cf. PSM keys                                                                                                                                                                                                                                                                        |
| pep\_start      | Ordinal position of first peptide residue in protein sequence                             |                                                                                                                                                                                                                                                                                     |
| pep\_end        | Mascot: ordinal position of last peptide residue in protein sequence                      |                                                                                                                                                                                                                                                                                     |
| gene            | Protein gene name                                                                         |                                                                                                                                                                                                                                                                                     |
| m/z             | The mass-over-charge of the precursor ion.                                                | Cf. PSM keys                                                                                                                                                                                                                                                                        |
| acc\_type       | The type of accession names                                                               | Cf. PSM keys                                                                                                                                                                                                                                                                        |
| entrez          | Protein Entrez ID                                                                         |                                                                                                                                                                                                                                                                                     |
| uniprot\_id     | Uniprot ID                                                                                | Cf. PSM keys                                                                                                                                                                                                                                                                        |
| species         | The species of a protein entry                                                            |                                                                                                                                                                                                                                                                                     |
| kin\_attr       | The attribute of proteins being kinases                                                   | Cf. PSM keys                                                                                                                                                                                                                                                                        |
| kin\_class      | The classes of kinases, e.g., TK, TKL…                                                    | Cf. PSM keys                                                                                                                                                                                                                                                                        |
| kin\_order      | The order of “kin\_class” from the kinase tree diagram                                    | Cf. PSM keys                                                                                                                                                                                                                                                                        |
| is\_tryptic     | Logical indicating if a sequence belongs to a canonical tryptic peptide                   |                                                                                                                                                                                                                                                                                     |
| kin\_attr       | The attribute of proteins being kinases                                                   | Cf. PSM keys                                                                                                                                                                                                                                                                        |
| kin\_class      | The classes of kinases, e.g., TK, TKL…                                                    | Cf. PSM keys                                                                                                                                                                                                                                                                        |
| kin\_order      | The order of “kin\_class” from the kinase tree diagram                                    | Cf. PSM keys                                                                                                                                                                                                                                                                        |
| …               | More column keys from MaxQuant                                                            | Median description for the keys of “Score”, “PEP”, “Charge”, “Mass”, “PIF”, “Fraction of total spectrum”, “Mass error \[ppm\]”, “Mass error \[Da\]”, “Base peak fraction”, “Precursor Intensity”, “Precursor Apex Fraction”, “Intensity coverage”, “Peak coverage”, “Combinatorics” |
| I… (…)          | Reporter-ion intensity                                                                    | Calculated from the descriptive statistics by `method_psm_pep` in `normPep()` for indicated samples                                                                                                                                                                                 |
| N\_I… (…)       | Normalized I… (…)                                                                         | The calibration factors for the alignment of log2FC are used to scale the reporter-ion intensity                                                                                                                                                                                    |
| sd\_log2\_R (…) | Standard deviation of protein log2FC                                                      | Calculated from contributing peptides under each sample                                                                                                                                                                                                                             |
| log2\_R (…)     | log2FC relative to reference materials for indicated samples                              | Before normalization                                                                                                                                                                                                                                                                |
| N\_log2\_R (…)  | Aligned log2\_R (…) according to method\_align in normPep() without scaling normalization |                                                                                                                                                                                                                                                                                     |
| Z\_log2\_R (…)  | N\_log2\_R (…) with scaling normalization                                                 |                                                                                                                                                                                                                                                                                     |

#### 4.2.3 Proteins

The corresponidng column keys are described below:

| Header         | Descrption                                                                                | Note                                                                                                |
| :------------- | :---------------------------------------------------------------------------------------- | :-------------------------------------------------------------------------------------------------- |
| gene           | Protein gene name                                                                         |                                                                                                     |
| prot\_cover    | Protein sequence coverage                                                                 | Cf. PSM keys                                                                                        |
| prot\_acc      | Protein accession string                                                                  | Cf. PSM keys                                                                                        |
| prot\_desc     | Protein description taken from Fasta title line                                           |                                                                                                     |
| prot\_mass     | Protein mass                                                                              |                                                                                                     |
| prot\_len      | The number of amino acid residues under a proposed protein                                |                                                                                                     |
| prot\_n\_psm   | Count of significant PSMs in quantitation under a proposed protein                        | Cf. Peptide keys                                                                                    |
| prot\_n\_pep   | Count of significant peptide sequences in quantitation under a proposed protein           | Cf. Peptide keys                                                                                    |
| m/z            | The mass-over-charge of the precursor ion.                                                | Cf. PSM keys                                                                                        |
| acc\_type      | The type of accession names                                                               |                                                                                                     |
| uniprot\_id    | Uniprot ID                                                                                | Cf. PSM keys                                                                                        |
| entrez         | Protein Entrez ID                                                                         |                                                                                                     |
| species        | The species of a protein entry                                                            |                                                                                                     |
| kin\_attr      | The attribute of proteins being kinases                                                   | Cf. PSM keys                                                                                        |
| kin\_class     | The classes of kinases, e.g., TK, TKL…                                                    | Cf. PSM keys                                                                                        |
| kin\_order     | The order of “kin\_class” from the kinase tree diagram                                    | Cf. PSM keys                                                                                        |
| is\_tryptic    | Logical indicating if a sequence belongs to a canonical tryptic peptide                   |                                                                                                     |
| …              | More column keys from MaxQuant                                                            | Median description from peptide data                                                                |
| I… (…)         | Reporter-ion intensity                                                                    | Calculated from the descriptive statistics by `method_pep_prn` in `normPrn()` for indicated samples |
| N\_I… (…)      | Normalized I… (…)                                                                         | Cf. Peptide keys                                                                                    |
| log2\_R (…)    | log2FC relative to reference materials for indicated samples                              | Before normalization                                                                                |
| N\_log2\_R (…) | Aligned log2\_R (…) according to method\_align in normPrn() without scaling normalization |                                                                                                     |
| Z\_log2\_R (…) | N\_log2\_R (…) with scaling normalization                                                 |                                                                                                     |

## References

<div id="refs" class="references">

<div id="ref-mertins2018np">

Philipp, Martins. 2018. “Reproducible Workflow for Multiplexed
Deep-Scale Proteome and Phosphoproteome Analysis of Tumor Tissues by
Liquid Chromatography-Mass Spectrometry.” *Nature Protocols* 13 (7):
1632–61. <https://doi.org/10.1038/s41596-018-0006-9>.

</div>

<div id="ref-hwickham2019advr">

Wickham, Hadley. 2019. *Advanced R*. 2nd ed. Chapman & Hall/CRC.
<https://adv-r.hadley.nz/>.

</div>

</div>

1.  The default file names begin with letter `F`, followed by six digits
    and ends with `.csv` in name extension.

2.  There are cases that the same peptide sequence being assigned to
    different proteins remain unambiguous. For example, peptide
    `MENGQSTAAK` can be found from either the middle region of protein
    `NP_510965` or the N-terminal of protein `NP_001129505`. In case of
    the additional information of protein, not peptide, N-terminal
    acetylation, the sequence can only come from `NP_001129505` between
    the two candidate proteins. In addition to handling such exceptions,
    the nomenclature in `proteoQ` will annotate the former as
    `K.MENGQSTAAK.L` and the later as `-._MENGQSTAAK.L`.

3.  To extract the names of RAW MS files under a `raw_dir` folder:
    `extract_raws(raw_dir)`. Very occasionally, there may be RAW files
    without PSM contributions. In this case, the file names will be
    shown as missing by the program and need to be removed from
    `expt_smry.xlsx` or `frac_smry.xlsx`. The function
    `extract_psm_raws(dat_dir)` was developed to extract the list of RAW
    files that are actually present in PSM files.

4.  A slightly more thoughtful way to align PSM data might involve back
    propagations. For example after protein normalization, we apply the
    same offsets to back calculate pepitde and then PSM `log2FC`.

5.  On top of technical variabilities, the ranges of CV may be further
    subject to the choice of reference materials. Examples are available
    in Lab 3.1.

6.  Density kernel estimates can occasionally capture spikes in the
    profiles of log2FC during data alignment. Users will need to inspect
    the alignment of ratio histograms and may optimize the data
    normalization in full with different combinations of tuning
    parameters or in part against a subset of samples, before proceeding
    to the next steps.

7.  `normPep()` will report log2FC results both before and after the
    scaling of standard deviations.

8.  System parameters will be automatically updated from the modified
    `expt_smry.xlsx`

9.  The default is `scale_log2r = TRUE` throughout the package. When
    calling functions involved parameter `scale_log2r`, users can
    specify explicitly `scale_log2r = FALSE` if needed, or more
    preferably define its value under the global environment.

10. There are finer distinctions for what piece of data to be loaded
    later in the workflow. In the example of peptide data, the `proteoQ`
    program will determine automatically which file to use among
    `Peptide.txt`, `Peptide_impNA.txt`, `Peptide_pVals.txt` and
    `Peptide_impNA_pvals.txt`. The same is true for protein data. The
    choice depends on the availablity in the imputation of NA values
    and/or the assessment of stastical significance.

11. This will work as GO terms of human start with `hs_` and KEGG terms
    with `hsa`.

12. Details on the notation of peptide modifications can be found via
    `?normPSM`.
