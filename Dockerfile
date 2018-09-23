FROM java:openjdk-8-jre

MAINTAINER CARYN MCCOWAN cmccowan@broadinstitute.org

#Set up working directory
WORKDIR /usr

# Update system, Install python, r, XML, rsync
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y apt-utils  && \
    apt-get install -y python-pip && \
    apt-get install -y python-dev && \
    apt-get install -y python-tk && \
    apt-get install -y python3-pip && \
    apt-get install -y r-base && \
    apt-get install -y libxml2-dev && \
    apt-get install -y rsync

# Install python packages
RUN python -mpip install -U pip && \
    python -mpip install -U matplotlib && \
    python -mpip install -U numpy && \
    python -mpip install -U biopython && \
    python -mpip install -U openpyxl

# Set locale **required for SMRTtools to function properly)**
# This was really tricky to set up
# Correct code was found here: https://github.com/tianon/docker-brew-debian/issues/45#issuecomment-325235517
RUN apt-get clean && apt-get update && apt-get install -y locales && \
    echo "LC_ALL=en_US.UTF-8" >> /etc/environment && \
    echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen && \
    echo "LANG=en_US.UTF-8" > /etc/locale.conf && \
    locale-gen en_US.UTF-8


# Install SMRTtools and remove unnecessary server files
RUN wget 'https://downloads.pacbcloud.com/public/software/installers/smrtlink_5.1.0.26412.zip'  && \
    unzip -P 9rVkq3HT smrtlink_5.1.0.26412.zip && \
    SMRT_ROOT=/pacbio/smrtlink && \
    ./smrtlink_5.1.0.26412.run --rootdir $SMRT_ROOT --smrttools-only && \
    /pacbio/smrtlink/install/smrtlink-release_5.1.0.26412/private/bundles/smrttools/smrttools-release_5.1.0.26366_linux_x86-64_libc-2.5_ubuntu-1404.run  --rootdir /PBtools && \
    rm -r /pacbio smrtlink_5.1.0.26412.*  #clean up
    #executable tools are available at this path: /PBtools/smrtcmds/bin
