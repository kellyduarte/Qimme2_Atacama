rule all:
    input:
        "results/importqza/emp-paired-end-sequences.qza"
"""
rule inputqiime:
    input:
        F = "data/emp-paired-end-sequences/forward.fastq.gz",
        R = "data/emp-paired-end-sequences/reverse.fastq.gz",
        B = "data/emp-paired-end-sequences/barcodes.fastq.gz"
    output:
        "results/importqza/emp-paired-end-sequences.qza"
    conda:
        "envs/qiime2.yaml" #erro nesse arquivo
    shell:
        "qiime tools import "
        "--type EMPPairedEndSequences "
        "{input.F} {input.R} {input.B} "  #lê de trás pra frente #trocar o params se não funci
        "--output-path {output} " #só especifica se for mais de um

"""
rule demux:
    input:
       "results/importqza/emp-paired-end-sequences.qza"
    output:
         demu_qza = "results/demultiplex/demux-full.qza"
         demu_details = "results/demultiplex/demux-details.qza"
    conda:
        "envs/qiime2.yaml"
    shell:
        "qiime demux emp-paired"
        "--m-barcodes-file sample-metadata.tsv"
        "--m-barcodes-column barcode-sequence"
        "--p-rev-comp-mapping-barcodes"
        "--i-seqs emp-paired-end-sequences.qza"
        "--o-per-sample-sequences {output.demu_qza}"
        "--o-error-correction-details {output.demu_details}"

rule subsample:
    input:
      "results/demultiplex/demux-full.qza"
    output:
        "results/demultiplex/demux-subsample.qza"
    conda:
        "envs/qiime2.yaml"
    shell:
        "qiime demux subsample-paired, "
        "--i-sequences demux-full.qza "
        "--p-fraction 0.3 "
        "--o-subsampled-sequences demux-subsample.qza "

rule demux_visualization:
    input:
        "results/demultiplex/demux-subsample.qza "
    output:
        "results/demultiplex/demux-subsample.qzv "
    conda:
        "envs/qiime2.yaml"
    shell:
        "qiime demux summarize ",
        "--i-data demux-subsample.qza ",
        "--o-visualization demux-subsample.qzv"

rule demux_subsample:
    input:
        demu_sub_qza = "results/demultiplex/demux-subsample.qza",
        demu_sub_qzv = "results/demultiplex/demux-subsample.qzv"
    output:
        "results/demultiplex/demux.qza"
    conda:
        "envs/qiime2.yaml"
    shell:
        "qiime tools export"
        "--input-path {output.demu_sub_qza}"
        "--output-path ./results/demultiplex/demux-subsample"
        "qiime demux filter-samples"
        "--i-demux results/demultiplex/demux-subsample.qza"
        "--m-metadata-file ./demux-subsample/per-sample-fastq-counts.tsv"
        "--p-where 'CAST([forward sequence count] AS INT) > 100'"
        "--o-filtered-demux results/demultiplex/demux.qza"
    
rule denoise:
    input:
        "results/demultiplex/demux.qza"
    output:
        denoi_status = "results/denoise/denoising-stats.qza"
        rep_seq = "results/denoise/rep-seqs.qza"
        table_qza = "results/denoise/table.qza"
    conda:

    shell:
        "qiime dada2 denoise-paired"
        "--i-demultiplexed-seqs demux.qza"
        "--p-trim-left-f 13"
        "--p-trim-left-r 13"
        "--p-trunc-len-f 150"
        "--p-trunc-len-r 150"
        "--o-table table_qza"
        "--o-representative-sequences {output.rep_seq}"
        "--o-denoising-stats {output.denoi_status}"

rule table:
    input:
        table_qza        #não sei se posso chamar a variável como input
    output:
        "results/denoise/table.qzv"
    conda:

    shell:
        "qiime feature-table summarize"
        "--i-table table.qza"
        "--o-visualization table.qzv"
        "--m-sample-metadata-file sample-metadata.tsv"
        
rule rep:
    input:
        rep_seq
    output:
        "results/denoise/rep-seqs.qzv"
    conda:

    shell:
        "qiime feature-table tabulate-seqs"
        "--i-data {input.rep_seq}"
        "--o-visualization rep-seqs.qzv"

rule status:
    input:
        denoi_status  
    output:
        "results/denoise/denoising-stats.qzv" 
    conda:

    shell:         
        "qiime metadata tabulate"
        "--m-input-file {input.denoi_status}"
        "--o-visualization denoising-stats.qzv"

rule FeatureTable:
    input:
        table_qza
    output:
        "results/featureTable/table.qzv"
    conda:

    shell:
        "qiime feature-table summarize"
        "--i-table table.qza"
        "--o-visualization table.qzv"
        "--m-sample-metadata-file sample-metadata.tsv"
        
rule rep_seqs:
    input:
        rep_seq
    output:
        "results/featureTable/rep-seqs.qzv"
    conda:

    shell:  
        "qiime feature-table tabulate-seqs"
        "--i-data rep-seqs.qza"
        "--o-visualization rep-seqs.qzv"

rule phylogenetic:
    input:
        rep_seq
    output:
        aligned = "aligned-rep-seqs.qza"
        masked = "masked-aligned-rep-seqs.qza"
        tree = "rooted-tree.qza"
        utree = "unrooted-tree.qza"
    shell:
        "qiime phylogeny align-to-tree-mafft-fasttree"
        "--i-sequences rep_seq"
        "--o-alignment {output.aligned}"
        "--o-masked-alignment {output.masked}"
        "--o-tree {output.tree}"
        "--o-rooted-tree {output.utree}"

#Alpha and beta diversity analysis¶
"""
rule diversity:
    input:  
        "aligned-rep-seqs.qza"
        "masked-aligned-rep-seqs.qza"
        "rooted-tree.qza"
        "unrooted-tree.qza"
    output:
"""