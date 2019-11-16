cd /opt &&
rm -r /opt/aspire && \
mkdir -p /opt/aspire/audio && \
mkdir -p /opt/aspire/transcripts && \
wget -O /opt/aspire/audio/samplefile1.wav https://raw.githubusercontent.com/suryavan11/kaldi_offline/master/samplefile.wav && \
for i in {2..4}; do cp /opt/aspire/audio/samplefile1.wav "/opt/aspire/audio/samplefile$i.wav"; done

 
paste <(ls /opt/aspire/audio/*.wav | xargs -n 1 basename | sed -e 's/\.wav$//') <(ls -d /opt/aspire/audio/*.wav) > /opt/aspire/wav.scp && \
paste <(ls /opt/aspire/audio/*.wav | xargs -n 1 basename | sed -e 's/\.wav$//') <(ls /opt/aspire/audio/*.wav | xargs -n 1 basename | sed -e 's/\.wav$//') > /opt/aspire/utt2spk && \
cd /opt/kaldi/egs/aspire/s5  && \
. cmd.sh && \
. path.sh && \
utils/utt2spk_to_spk2utt.pl /opt/aspire/utt2spk > /opt/aspire/spk2utt && \
rm -rf data/eval2000_hires && \
rm -rf exp/nnet3/ivectors_eval2000 && \
rm -rf exp/chain/tdnn_7b/decode_eval2000_pp_tg && \
utils/copy_data_dir.sh /opt/aspire data/eval2000_hires && \
steps/make_mfcc.sh --mfcc-config conf/mfcc_hires.conf --nj 4 data/eval2000_hires && \
steps/compute_cmvn_stats.sh data/eval2000_hires && \
steps/compute_vad_decision.sh --nj 4 --vad-config /opt/kaldi/egs/callhome_diarization/v1/conf/vad.conf  data/eval2000_hires && \
/opt/kaldi/egs/callhome_diarization/v1/diarization/vad_to_segments.sh --nj 4 data/eval2000_hires data/eval2000_hires_seg && \
awk "{$1 $2}" data/eval2000_hires_seg/segments > utt2spk && \
utils/utt2spk_to_spk2utt.pl data/eval2000_hires_seg/utt2spk > data/eval2000_hires_seg/spk2utt && \
steps/make_mfcc.sh --mfcc-config conf/mfcc_hires.conf --nj 4 data/eval2000_hires_seg && \
steps/compute_cmvn_stats.sh data/eval2000_hires_seg && \
utils/fix_data_dir.sh data/eval2000_hires_seg && \
steps/online/nnet2/extract_ivectors.sh --nj 4 --cmd "run.pl" data/eval2000_hires_seg data/lang_pp_test exp/nnet3/extractor exp/nnet3/ivectors_eval2000 && \
steps/nnet3/decode.sh --nj 4 --cmd 'run.pl' --config conf/decode.config \
  --acwt 1.0 --post-decode-acwt 10.0 \
  --frames-per-chunk 50 --skip-scoring true \
  --online-ivector-dir exp/nnet3/ivectors_eval2000 \
  exp/chain/tdnn_7b/graph_pp data/eval2000_hires_seg \
  exp/chain/tdnn_7b/decode_eval2000_pp_tg && \
  for i in exp/chain/tdnn_7b/decode_eval2000_pp_tg/lat.*.gz; do lattice-best-path ark:"gunzip -c $(echo "$i") |" "ark,t:|int2sym.pl -f 2- exp/chain/tdnn_7b/graph_pp/words.txt > $(echo "$i" | sed -r "s/.+\/(.+)\.(.+)\.(.+)/\/opt\/aspire\/transcripts\/transcript\.\2\.txt/")"; done

