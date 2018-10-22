# WDL script that demultiplexes genomic data by barcode and submits one de-novo assembly job per de-multiplexed data set
# Requires SMRTtoolsV5.1.0 -->  Docker Image "ccmcowan/smrttools_cli"
# documentation for demultiplexing: https://github.com/PacificBiosciences/barcoding
# information HGAP workflow:  https://github.com/PacificBiosciences/Bioinformatics-Training/wiki/HGAP
# documentation for PBsmrtpipe


workflow demultiplexed_assembly {

  #input files
  File inputBAM
  File inputBAMIndex

  #path to docker image
  #push to docker hub, put address here
  String pacBioDocker = "ccmcowan/smrttools_cli"

  call limaDemultiplexBarcodes {

    input: inputBAM = inputBAM,
           inputBAMIndex = inputBAMIndex,
           pacBioDocker = pacBioDocker
  }


  #iterate over array index using scatter command
  scatter(arrayIndex in range(length(limaDemultiplexBarcodes.output_BAM))) {

    call HGAP_denovo_assembly {
      #passes the file located at the array index, arrays are organized according to file names
      input: limaOutputXML = limaDemultiplexBarcodes.limaOutputSubreadSets[arrayIndex],
             limaOutBAM = limaDemultiplexBarcodes.output_BAM[arrayIndex],
             limaOutPBI = limaDemultiplexBarcodes.output_BAMIndex[arrayIndex],

             #add in docker image
             pacBioDocker = pacBioDocker
    }

  call packUpBAMinput {

    input inputBAM = inputBAM

    }
  }

  #final workflow output
  output {

    #output arrays from assembly step
    Array[File] outputFASTAs = glob(HGAP_denovo_assembly.outputFASTA)
    Array[File] outputFASTQs = glob(HGAP_denovo_assembly.outputFASTQ)
    Array[File] outputJSONs = glob(HGAP_denovo_assembly.outputJSON)

    #output files from lima step
    File outLimaReport = limaDemultiplexBarcodes.lima_Report
    File outLimaSummary = limaDemultiplexBarcodes.lima_Summary

    #input as output
    File compressedBAM = limaDemultiplexBarcodes.compressedBAM

    }
}

###***INDIVIDUAL TASKS***###
#Task 1:  Run LIMA Splitter
task limaDemultiplexBarcodes {

  #task input variables
  File inputBAM
  File inputBAMIndex
  File barcodeFASTA
  String outputPrefix
  String? optionalVariable

  #####runtime variables
  String pacBioDocker
  #multiply by 2 to account for output bam files (including orphan diretory)
  Int disk_size = ceil(2 * size(inputBAM, "GB") + 20)

  command {

    #must include the --split-bam option in order to return separate files
    /PBtools/smrtcmds/bin/lima ${inputBAM} ${barcodeFASTA} ${outputPrefix}.bam --split-bam ${optionalVariable}
    tar -zcvf ${inputBAM}.bam.tar.gz ${inputBAM}

  }

  runtime {

    docker: "${pacBioDocker}"
    cpu: "4"
    memory: "10GB"
    disks: "local-disk " + disk_size + " HDD"
    preemptible: preemptible_tries
  }

  output {


    File lima_Report = "${outputPrefix}.lima.report"
    File lima_Summary = "${outputPrefix}.lima.summary"
    File lima_Counts = "${outputPrefix}.lima.counts"
    File lima_Wrapper = "${outputPrefix}.json"
    #generate arrays of files using the glob() function
    Array[File] limaOutputSubreadSets = glob("*_${outputPrefix}.subreadset.xml")
    Array[File] output_BAM = glob("*_${outputPrefix}.bam")
    Array[File] output_BAMIndex = glob("*_$(outputPrefix).bam.pbi")
    #make sure to return packaged bam file
    File compressedBAM = "${inputBAM}.bam.tar.gz"
  }

}

#Task 2:  Feed Demultiplexed XMLs into HGAP
task HGAP_denovo_assembly {

  File limaOutputXML
  File limaOutBAM
  File limaOutPBI
  String projectID
  String? optionalInput
  File?  optionalPresetXML
  File runtimexml


  #runtime
  String pacBioDocker
  #process produces 0.5 GB of extra files (including output)
  Int disk_size = ceil(size(limaOutBAM, "GB") + 20)

  # The default command uses the subreadsed.xml file as the primary input
  command {

    /PBtools/smrtcmds/bin/pbsmrtpipe pipeline-id pbsmrtpipe.pipelines.polished_falcon_fat -e "eid_subread:/${limaOutputXML}" ${optionalInput} ${optionalPresetXML} --preset-xml ${runtimexml}
    tar -zcvf ${projectID}.fasta.tar.gz ${projectID}.fasta
    tar -zcvf ${projectID}.fastq.tar.gz ${projectID}.fastq
  }


  runtime {

           docker: "${pacBioDocker}"
           memory:  "10GB"
           cpu:  "16"
           disks: "local-disk " + disk_size + " HDD"
           preemptible: preemptible_tries
  }

  output {

    File outputFASTA = "${projectID}.fasta.tar.gz"
    File outputFASTQ = "${projectID}.fastq.tar.gz"
    File outputJSON = "{$ProjectID}.json"

  }
