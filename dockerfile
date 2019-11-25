FROM debian:9.8
LABEL maintainer="Abhijit Suryavanshi"

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        g++ \
        make \
        automake \
        autoconf \
        bzip2 \
        unzip \
        wget \
        sox \
        libtool \
        git \
        subversion \
        python2.7 \
        python3 \
        zlib1g-dev \
        ca-certificates \
        gfortran \
        patch \
        ffmpeg \
        nano \
	vim && \
    apt-get clean autoclean && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/* && \
    ln -s /usr/bin/python2.7 /usr/bin/python 

RUN git clone --depth 1 https://github.com/kaldi-asr/kaldi.git /opt/kaldi && \
    cd /opt/kaldi && \
    cd /opt/kaldi/tools && \
    ./extras/install_mkl.sh && \
    make -j $(nproc) && \
    cd /opt/kaldi/src && \
    ./configure --shared && \
    make depend -j $(nproc) && \
    make -j $(nproc)
    
RUN rm -rf /opt/kaldi/.git && \
    rm -rf /opt/kaldi/egs/ /opt/kaldi/windows/ /opt/kaldi/misc/ && \
    find /opt/kaldi/src/ -type f -not -name '*.so' -delete && \
    find /opt/kaldi/tools/ -type f \( -not -name '*.so' -and -not -name '*.so*' \) -delete

RUN mkdir -p /opt/kaldi/egs/aspire/s5 && \
cd /opt/kaldi/egs/aspire/s5  && \
wget http://dl.kaldi-asr.org/models/0001_aspire_chain_model.tar.gz && \
tar xfv 0001_aspire_chain_model.tar.gz && \
steps/online/nnet3/prepare_online_decoding.sh --mfcc-config conf/mfcc_hires.conf data/lang_chain exp/nnet3/extractor exp/chain/tdnn_7b exp/tdnn_7b_chain_online && \
utils/mkgraph.sh --self-loop-scale 1.0 data/lang_pp_test exp/tdnn_7b_chain_online exp/tdnn_7b_chain_online/graph_pp 

RUN cd /opt/kaldi/egs/aspire/s5  && \
rm -rf 0001_aspire_chain_model.tar.gz && \
cd /opt/kaldi/egs/callhome_diarization && \
wget http://kaldi-asr.org/models/6/0006_callhome_diarization_v2_1a.tar.gz && \
tar xfv 0006_callhome_diarization_v2_1a.tar.gz && \
rm -rf 0006_callhome_diarization_v2_1a.tar.gz && \
cd /opt/kaldi/egs/callhome_diarization && \
wget http://kaldi-asr.org/models/4/0004_tdnn_stats_asr_sad_1a.tar.gz && \
tar xfv 0004_tdnn_stats_asr_sad_1a.tar.gz && \
rm -rf 0004_tdnn_stats_asr_sad_1a.tar.gz

COPY model_SAD_diarize_transcribe.sh /opt/

RUN chmod +x /opt/model_SAD_diarize_transcribe.sh

WORKDIR /opt
