# Standalone WDL script for Pacific Biosciences Lima Barcode Splitter
# Requires SMRTtoolsV5.1.0
# documentation: https://github.com/PacificBiosciences/barcoding
# maintained by:  Caryn McCowan

# command sturctur:e  lima <mymoviebamfile>.bam <mybarcodefile>.fasta <myoutputprefix>.bam

workflow Lima {

  call limaDemultiplexBarcodes {
                                input: inputBAM = limaDemultiplexBarcodes.inputBAM,
                                inputBAMIndex = limaDemultiplexBarcodes.inputBAMIndex
                               }
    }
}

#Task 1:  Run LIMA
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
