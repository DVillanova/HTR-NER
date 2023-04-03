# set -e
export LC_NUMERIC=C.UTF-8;

conda activate pylaia

#Varables, parameters and routes for Docker
GPU=1
BatchSize=8
WorkDir=/root/directorioTrabajo/HTR-NER/NER_HOME/
ScriptsDir=/root/directorioTrabajo/HTR-NER/scripts/
PartDir=${WorkDir}/PARTITIONS
TextDir=${WorkDir}/TEXT
DataDir=${WorkDir}/DATA
LangDir=${WorkDir}/lang
CharDir=${LangDir}/char
ModelDir=${WorkDir}/model
TmpDir=${WorkDir}/TMP
NerDir=${WorkDir}/NER
NerNoRepDir=${WorkDir}/NER-NoRep
img_dirs=$(find ${DataDir}/*_charters -mindepth 3 -maxdepth 3 -type d)

echo "Measuring time it takes to apply syntactical constraints" > $WorkDir/results_exp_time.txt

#########################################
# TIME IT TAKES TO GENERATE THE LATTICE #
#########################################
ASF=0.818485839158                        # Acoustic Scale Factor
MAX_NUM_ACT_STATES=2007483647             # Maximum number of active states
BEAM_SEARCH=15                            # Beam search
LATTICE_BEAM=12                           # Lattice generation beam
N_CORES=1     

cd $TmpDir/decode
echo "** Lattice generation **" >> $WorkDir/results_exp_time.txt
start=`date +%s`
latgen-faster-mapped --verbose=2 --allow-partial=true --acoustic-scale=${ASF} --max-active=${MAX_NUM_ACT_STATES} --beam=${BEAM_SEARCH} --lattice-beam=${LATTICE_BEAM} --max-mem=4194304 $ModelDir/HMMs/train/new.mdl $ModelDir/HMMs/test/graph/HCLG.fst scp:test/confMats_alp0.3-test.scp "ark:|gzip -c > lattices/lat-test.gz" ark,t:lattices/RES-test 2>lattices/LOG-Lats-test
end=`date +%s`
runtime=$((end-start))
echo "Time: " ${runtime} >> $WorkDir/results_exp_time.txt


###################
# N-BEST DECODING #
###################
ASF=1.27216049
WIP=-0.76260881
MAX_NUM_ACT_STATES=2007483647             # Maximum number of active states
BEAM_SEARCH=15                            # Beam search
LATTICE_BEAM=12                           # Lattice generation beam
N_CORES=1   

echo "** n-best decoding **" >> $WorkDir/results_exp_time.txt
for N in 1 10 50 100 500 1000 2500 5000 10000
do
cd $TmpDir/decode/lattices

echo "==================" >> $WorkDir/results_exp_time.txt
echo "N = " ${N} >> $WorkDir/results_exp_time.txt

cp ${LangDir}/lm/lang/words.txt ./words.txt

start=`date +%s`

rm ${N}-best-lat-test.gz
lattice-scale --acoustic-scale=${ASF} "ark:gzip -c -d lat-test.gz |" ark:- | \
lattice-add-penalty --word-ins-penalty=${WIP} ark:- ark:- | \
lattice-to-nbest --n=${N} --acoustic-scale=${ASF} ark:- "ark:|gzip -c > ${N}-best-lat-test.gz"
#lattice-copy ark:'gunzip -c n_best-lat-test.gz|' ark,t:n_best-lat-test.txt
rm best-test-transcriptions.txt
nbest-to-linear "ark:gzip -c -d ${N}-best-lat-test.gz |" ark,t:${N}-best-test.ali 'ark,t:|int2sym.pl -f 2- words.txt > best-test-transcriptions.txt'

rm ${N}-best-test.ali
rm ${N}-best-test-words.txt

awk '{
printf("%s ", $1);
for (i=2;i<=NF;++i) {
  if ($i == "<space>")
    printf(" ");
  else
    printf("%s", $i);
}
printf("\n");
}' best-test-transcriptions.txt > ${N}-best-test-words.txt;

rm ${N}-best-compliant-test-words.txt
python $ScriptsDir/nbest_hyp_crawler.py ./${N}-best-test-words.txt ./${N}-best-compliant-test-words.txt $WorkDir/histogram-${N}-best.txt ./crawler-log.txt
python $ScriptsDir/char_transcript_extractor.py ./${N}-best-compliant-test-words.txt  ./${N}-best-compliant-test-chars.txt

end=`date +%s`
runtime=$((end-start))

echo "Time: " ${runtime} >> $WorkDir/results_exp_time.txt
done



################
# FSA DECODING #
################
echo "\n\n\n\n\n** Syntactical FSA **" >> $WorkDir/results_exp_time.txt


cd $LangDir/lm/
python $ScriptsDir/generate_categorical_sfsa.py $ModelDir/HMMs/test/graph/words.txt $WorkDir/CAT_FST/Categorical.fst
$ScriptsDir/prepare_lang_test_categorical.sh $WorkDir/CAT_FST/Categorical.fst lang lang_test "$DUMMY_CHAR"

cd $TmpDir/decode/lattices
start=`date +%s`
lattice-lmrescore --lm-scale=1.0 "ark:gzip -c -d lat-test.gz |" ${LangDir}/lm/lang_test/G_cat.fst "ark:|gzip -c > rescored_lat-test.gz"
$ScriptsDir/score.sh --wip $WIP --lmw $ASF $ModelDir/HMMs/test/graph/words.txt "ark:gzip -c -d rescored_lat-test.gz |" $LangDir/char/char.total.txt rescored_hypotheses-test 2>log

int2sym.pl -f 2- $LangDir/lm/lang_test/words.txt rescored_hypotheses-test > rescored_hypotheses-test_t
python $ScriptsDir/combine_hypotheses_files.py rescored_hypotheses-test_t hypotheses-test_t combined_hypotheses-test_t

awk '{
printf("%s ", $1);
for (i=2;i<=NF;++i) {
  if ($i == "<space>")
    printf(" ");
  else
    printf("%s", $i);
}
printf("\n");
}' combined_hypotheses-test_t > word-lm/combined_hyp_word-test.txt;

end=`date +%s`
runtime=$((end-start))

echo "Time: " ${runtime} >> $WorkDir/results_exp_time.txt