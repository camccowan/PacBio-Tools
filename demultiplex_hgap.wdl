# WDL script that demultiplexes genomic data by barcode and submits one de-novo assembly job per de-multiplexed data set
# Requires installation of SMRTtoolsV5.1.0
# documentation for demultiplexing: https://github.com/PacificBiosciences/barcoding
# information HGAP workflow:  https://github.com/PacificBiosciences/Bioinformatics-Training/wiki/HGAP
# documentation for PBsmrtpipe


workflow demultiplexed_assembly {

  File: inputBAM
  File: inputBAMIndex

  call limaDemultiplexBarcodes {
                                input: inputBAM = limaDemultiplexBarcodes.inputBAM,
                                input: inputBAMIndex = limaDemultiplexBarcodes.inputBAMIndex
                               }
  call HGAP_denovo_assembly {
                             input: limaOutputXMLs = limaDemultiplexBarcodes.limaOutputSubreadSets
                            }
    }
}

#Task 1:  Run LIMA to demultiplex barcodes
task limaDemultiplexBarcodes {

  File limaPath
  File inputBAM
  File inputBAMIndex
  File barcodeFASTA
  String outputPrefix
  String? optionalVariable

  command {${limaPath} ${inputBAM} ${barcodeFASTA} ${outputPrefix}.bam ${optionalVariable}}

  output {

    File output_BAM = "${outputPrefix}.bam"
    File output_BAMIndex = "$(outputPrefix).bam.pbi"
    File lima_Report = "${outputPrefix}.lima.report"
    File lima_Summary = "${outputPrefix}.lima.summary"
    File lima_Counts = "${outputPrefix}.lima.counts"
    File lima_Wrapper = "${outputprefix}.json"

    Array[File] limaOutputSubreadSets = "${outputPrefix}.subreadset.xml"

  }

}

#Task 2:  Feed Demultiplexed XMLs into HGAP
task HGAP_denovo_assembly {

  Array[file] limaOutputXMLs
  File limaOutBAM
  File smrtpipePath
  String projectID
  String? hgapPresets
  File?  optionalPresetXML

  command {${smrtpipePath} pipeline-id pbsmrtpipe.pipelines.polished_falcon_fat -e eid_subread:/${pathToXML} ${hgapPresets} ${optionalPresetXML}}

  output {

  File outputFASTA = "${projectID}.fasta"
  File outputFASTQ = "{projectID}.fastq"
  File outputJSON = "{ProjectID}.json"
  }
}
