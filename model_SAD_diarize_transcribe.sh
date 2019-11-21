#!/bin/bash

#### new model based diarization transcription - use rttm as starting point for transcription ###################

paste <(ls /opt/aspire/audio/*.wav | xargs -n 1 basename | sed -e 's/\.wav$//') <(ls -d /opt/aspire/audio/*.wav) > /opt/aspire/wav.scp && \
paste <(ls /opt/aspire/audio/*.wav | xargs -n 1 basename | sed -e 's/\.wav$//') <(ls /opt/aspire/audio/*.wav | xargs -n 1 basename | sed -e 's/\.wav$//') > /opt/aspire/utt2spk && \
paste <(ls /opt/aspire/audio/*.wav | xargs -n 1 basename | sed -e 's/\.wav$//') <(ls /opt/aspire/audio/*.wav | sed -e 's/.*/2/g' ) > /opt/aspire/reco2num_spk && \
cd /opt/kaldi/egs/aspire/s5  && \
. cmd.sh && \
. path.sh && \
utils/utt2spk_to_spk2utt.pl /opt/aspire/utt2spk > /opt/aspire/spk2utt && \
rm -rf data/eval2000_* && \
rm -rf exp/nnet3/ivectors_eval2000 && \
rm -rf exp/chain/tdnn_7b/decode_eval2000_pp_tg && \
utils/copy_data_dir.sh /opt/aspire data/eval2000_hires && \
cd /opt/kaldi/egs/wsj/s5 && \
steps/segmentation/detect_speech_activity.sh \
	--nj 4 \
	--cmd "/opt/kaldi/egs/wsj/s5/utils/run.pl" \
   --extra-left-context 79 --extra-right-context 21 \
   --extra-left-context-initial 0 --extra-right-context-final 0 \
   --frames-per-chunk 150 --mfcc-config /opt/kaldi/egs/callhome_diarization/conf/mfcc_hires.conf \
   /opt/kaldi/egs/aspire/s5/data/eval2000_hires \
   /opt/kaldi/egs/callhome_diarization/exp/segmentation_1a/tdnn_stats_asr_sad_1a \
   /opt/kaldi/egs/aspire/s5/data/eval2000_hires_seg \
   /opt/kaldi/egs/aspire/s5/data/eval2000_hires_temp \
   /opt/kaldi/egs/aspire/s5/data/eval2000_hires && \
cd /opt/kaldi/egs/aspire/s5  && \
steps/make_mfcc.sh --mfcc-config /opt/kaldi/egs/callhome_diarization/0006_callhome_diarization_v2_1a/conf/mfcc.conf \
--nj 4 --write-utt2num-frames true \
data/eval2000_hires_seg exp/make_mfcc data/eval2000_hires_seg_mfcc && \
utils/fix_data_dir.sh data/eval2000_hires_seg && \
/opt/kaldi/egs/callhome_diarization/v1/local/nnet3/xvector/prepare_feats.sh --nj 4 data/eval2000_hires_seg data/eval2000_hires_seg_cmn exp/eval2000_hires_seg && \
cp data/eval2000_hires_seg/segments data/eval2000_hires_seg_cmn/ && \
utils/fix_data_dir.sh data/eval2000_hires_seg_cmn && \
/opt/kaldi/egs/callhome_diarization/v1/diarization/nnet3/xvector/extract_xvectors.sh  \
--cmd "/opt/kaldi/egs/wsj/s5/utils/run.pl" \
--nj 4 --window 1.5 --period 0.75 --apply-cmn false \
--min-segment 0.5 \
/opt/kaldi/egs/callhome_diarization/0006_callhome_diarization_v2_1a/exp/xvector_nnet_1a \
data/eval2000_hires_seg_cmn \
/opt/kaldi/egs/callhome_diarization/0006_callhome_diarization_v2_1a/exp/xvector_nnet_1a/xvectors_eval2000_hires_seg && \
/opt/kaldi/egs/callhome_diarization/v1/diarization/nnet3/xvector/score_plda.sh \
--cmd "/opt/kaldi/egs/wsj/s5/utils/run.pl" \
--target-energy 0.9 --nj 4 \
/opt/kaldi/egs/callhome_diarization/0006_callhome_diarization_v2_1a/exp/xvector_nnet_1a/xvectors_callhome2 \
/opt/kaldi/egs/callhome_diarization/0006_callhome_diarization_v2_1a/exp/xvector_nnet_1a/xvectors_eval2000_hires_seg \
/opt/kaldi/egs/callhome_diarization/0006_callhome_diarization_v2_1a/exp/xvector_nnet_1a/xvectors_eval2000_hires_seg/plda_scores && \
cd /opt/kaldi/egs/callhome_diarization/v1/ && \
/opt/kaldi/egs/callhome_diarization/v1/diarization/cluster.sh \
--cmd "/opt/kaldi/egs/wsj/s5/utils/run.pl" \
--nj 4 \
--reco2num-spk /opt/aspire/reco2num_spk \
/opt/kaldi/egs/callhome_diarization/0006_callhome_diarization_v2_1a/exp/xvector_nnet_1a/xvectors_eval2000_hires_seg/plda_scores \
/opt/kaldi/egs/callhome_diarization/0006_callhome_diarization_v2_1a/exp/xvector_nnet_1a/xvectors_eval2000_hires_seg/plda_scores_num_speakers && \
cp /opt/kaldi/egs/callhome_diarization/0006_callhome_diarization_v2_1a/exp/xvector_nnet_1a/xvectors_eval2000_hires_seg/plda_scores_num_speakers/rttm /opt/aspire/transcripts && \
cd /opt/kaldi/egs/aspire/s5 && \
mkdir data/eval2000_hires1 && \
cp /opt/aspire/{wav.scp,utt2spk,spk2utt} data/eval2000_hires1 && \
utils/fix_data_dir.sh data/eval2000_hires1 
mkdir data/eval2000_hires_seg1 && \
cp /opt/aspire/wav.scp data/eval2000_hires_seg1 && \
awk '{print $2 "-" sprintf("%07i", $4*100) "-" sprintf("%07i", ($4 + $5)*100) "-" $8, $2, $4, $4+$5  }' \
/opt/kaldi/egs/callhome_diarization/0006_callhome_diarization_v2_1a/exp/xvector_nnet_1a/xvectors_eval2000_hires_seg/plda_scores_num_speakers/rttm  > \
data/eval2000_hires_seg1/segments && \
awk '{print $1,$2 }' data/eval2000_hires_seg1/segments > data/eval2000_hires_seg1/utt2spk && \
utils/fix_data_dir.sh data/eval2000_hires_seg1 && \
steps/make_mfcc.sh --mfcc-config conf/mfcc_hires.conf --nj 4 data/eval2000_hires_seg1 && \
steps/compute_cmvn_stats.sh data/eval2000_hires_seg1 && \
utils/fix_data_dir.sh data/eval2000_hires_seg1 && \
steps/online/nnet2/extract_ivectors.sh --nj 4 --cmd "run.pl" \
data/eval2000_hires_seg1 \
data/lang_pp_test \
exp/nnet3/extractor \
exp/nnet3/ivectors_eval2000 && \
steps/nnet3/decode.sh --nj 4 --cmd 'run.pl' --config conf/decode.config \
  --acwt 1.0 --post-decode-acwt 10.0 \
  --beam 15 --lattice_beam 6 \
  --frames-per-chunk 50 --skip-scoring true \
  --online-ivector-dir exp/nnet3/ivectors_eval2000 \
  exp/chain/tdnn_7b/graph_pp data/eval2000_hires_seg1 \
  exp/chain/tdnn_7b/decode_eval2000_pp_tg && \
  for i in exp/chain/tdnn_7b/decode_eval2000_pp_tg/lat.*.gz; do lattice-best-path ark:"gunzip -c $(echo "$i") |" "ark,t:|int2sym.pl -f 2- exp/chain/tdnn_7b/graph_pp/words.txt" | sed -r 's/\s+/|/' | awk -F'|' -v OFS='|' '{x=$1;y=gsub(/-/,"|",$1);print x,$1,$2}' > $(echo "$i" | sed -r "s/.+\/(.+)\.(.+)\.(.+)/\/opt\/aspire\/transcripts\/transcript\.\2\.txt/"); done
