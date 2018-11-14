## WDL script to assemble a microbial de novo genome from PacBio using the Unicycler assembler
## This WDL also supports the addition of short read data to create a hybrid assembly
## This requires the unicycler docker image from DockerHub --> docker pull nwflorek/unicycler

workflow BAMtoUnicycler {

  #input files
  File inputBAM
  File inputBAMIndex

  #path to docker image:  ccmcowan/smrttools_cli
  String pacBioDocker

  #demultiplex barcodes
  call limaDemultiplexBarcodes {

    input: inputBAM = inputBAM,
           inputBAMIndex = inputBAMIndex,
           pacBioDocker = pacBioDocker
  }

  #iterate over array index using scatter command
  scatter(arrayIndex in range(length(limaDemultiplexBarcodes.output_BAM))) {

    call pbBAMtoFastq {
      #passes the file located at the array index, arrays are organized according to file names
      input:
             limaOutBAM = limaDemultiplexBarcodes.output_BAM[arrayIndex],
             #add in docker image
             pacBioDocker = pacBioDocker
    }
  }

  #iterate over array index using scatter command
  scatter(arrayIndex in range(length(limaDemultiplexBarcodes.output_BAM))) {

    call UnicyclerAssembly {
      #passes the file located at the array index, arrays are organized according to file names
      input: PacBiofastq = pbBAMtoFastq.PacBiofastq[arrayIndex]

             #docker image is in the task block
    }
  }



}

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
  Int? preemptible_tries

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
    preemptible: select_first([preemptible_tries, 3])
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

task pbBAMtoFastq {
#the PacBio BAM format MUST be converted to a fastq.gz file before the Unicycler assembly step
  File pbBAM

  Int disk_size = ceil(((2*size(pbBAM, "GB")) + 20)

  command { /PBtools/smrtcmds/bin/bam2fastq ${pbBAM}}

  runtime {

    docker: "{pacBioDocker}"
    cpu: "4"
    memory: "10GB"
    disks: "local-disk " + disk_size + " HDD"
    preemptible: preemptible_tries
  }

  output {

    File PacBiofastq = "${*.fastq.gz}"

  }
}

task unicyclerAssembly{

  #must be in fastq.gz format
  String assemblyName
  String? R1
  String? R2
  File? illuminaR1
  File? illuminaR2
  File PacBiofastq
  String keepLevel

  Int disk_size = ceil(size(PacBiofastq, "GB") + (2*size(illuminaR1)) + 20)

  command { unicycler ${R1} ${illuminaR1} ${R2} ${illuminaR2} -l ${PacBiofastq} ${keepLevel}}

  runtime {

    docker: "nwflorek/unicycler"
    memory:  "10GB"
    cpu:  "16"
    disks: "local-disk " + disk_size + " HDD"
    preemptible: preemptible_tries

  }

  output {

    File outFASTA = "${assemblyName}.fasta"
    File outGFA = "${assemblyName}.gfa"
    File outLog = "unicycler.log"


  }

}
