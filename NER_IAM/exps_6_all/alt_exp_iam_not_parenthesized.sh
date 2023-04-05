# set -e

export LC_NUMERIC=C.UTF-8;

conda activate pylaia

#Variables, parameters and routes for Docker
GPU=2
BatchSize=4
WorkDir=/root/directorioTrabajo/DOC-NER/HTR-NER/NER_IAM/
ScriptsDir=/root/directorioTrabajo/DOC-NER/HTR-NER/scripts/
PartDir=${WorkDir}/PARTITIONS
TextDir=${WorkDir}/ALT_6_NOT_PARENTHESIZED_TEXT
DataDir=${WorkDir}/DATA/
LangDir=${WorkDir}/ALT_6_NOT_PARENTHESIZED_lang
CharDir=${LangDir}/char
ModelDir=${WorkDir}/ALT_6_NOT_PARENTHESIZED_model
TmpDir=${WorkDir}/ALT_6_NOT_PARENTHESIZED_TMP
NerDir=${WorkDir}/NER
NerNoRepDir=${WorkDir}/NER-NoRep

img_dirs=$(find ${DataDir}/lines -mindepth 2 -maxdepth 2 -type d)

##################################################################################################################################################################################
cd $WorkDir
rm -rf ${TextDir}
mkdir ${TextDir}

python $ScriptsDir/IAM_generate_tagged_line_transcription.py 2 \
       $WorkDir/ne_annotations/iam_all_custom_6_all.txt $DataDir/ascii/lines.txt \
       $TextDir/index.words

cd ${TextDir}

# Create data dir
cd ${WorkDir}
rm -rf ${CharDir}
mkdir -p ${CharDir}
cd ${CharDir}

cat ${TextDir}/index.words | awk '{
        printf("%s", $1);
        for(i=2;i<=NF;++i) {
                if($i!~"@"){  
                        for(j=1;j<=length($i);++j) 
                                printf(" %s", substr($i, j, 1));
                        if ((i < NF) && ($(i+1)!~"@")) printf(" <space>");
                }else{ 
                        printf " "$i" ";
                        if (i < NF) printf("<space>");
                }; 
        }
        printf("\n");
}' | sed 's/"/'\'' '\''/g;s/#/<stroke>/g' > char.total.txt

#Extract vocabulary and number of symbols in vocabulary
cat char.total.txt | cut -f 2- -d\  | tr \  \\n| sort -u -V | awk 'BEGIN{   N=0;   printf("%-12s %d\n", "<eps>", N++);   printf("%-12s %d\n", "<ctc>", N++);  }NF==1{  printf("%-12s %d\n", $1, N++);}' >  symb.txt
# NSYMBOLS=$(sed -n '${ s|.* ||; p; }' "symb.txt");


mkdir $PartDir
cd ${PartDir}

python $ScriptsDir/IAM_generate_part_files.py $WorkDir/ne_annotations/iam_train_custom_6_all.txt $TextDir/index.words $PartDir/train.lst
python $ScriptsDir/IAM_generate_part_files.py $WorkDir/ne_annotations/iam_test_custom_6_all.txt $TextDir/index.words $PartDir/test.lst
python $ScriptsDir/IAM_generate_part_files.py $WorkDir/ne_annotations/iam_valid_custom_6_all.txt $TextDir/index.words $PartDir/val.lst


#GENERATE .TXT FILES WITH TRANSCRIPTION AND LINE ID
#FROM .LST FILES (PARTITION) AND INDEX.WORDS
rm -rf ${TmpDir}
mkdir ${TmpDir}
cd ${TmpDir}

cp ${PartDir}/test.lst ./test.lst
cp ${PartDir}/train.lst ./train.lst
cp ${PartDir}/val.lst ./val.lst

for f in $(<./train.lst); do grep "${f}\b" ${TextDir}/index.words; done > ./train.txt
for f in $(<./test.lst); do grep "${f}\b" ${TextDir}/index.words; done > ./test.txt
for f in $(<./val.lst); do grep "${f}\b" ${TextDir}/index.words; done > ./val.txt

# CREATION CHAR.TRAIN CHAR.VAL CHAR.TEST
for f in $(<./train.lst); do grep "${f}\b" ${TextDir}/index.words; done |
awk '{
  printf("%s", $1);
  for(i=2;i<=NF;++i) {
    if($i!~"@"){  
      for(j=1;j<=length($i);++j) 
        printf(" %s", substr($i, j, 1));
      if ((i < NF) && ($(i+1)!~"@")) printf(" <space>");
    }else{ 
      printf " "$i" ";
      if (i < NF) printf("<space>");
    }; 
  }
  printf("\n");
}' | sed 's/"/'\'' '\''/g;s/#/<stroke>/g' > char.train.txt

for f in $(<./val.lst); do grep "${f}\b" ${TextDir}/index.words; done |
awk '{
  printf("%s", $1);
  for(i=2;i<=NF;++i) {
    if($i!~"@"){  
      for(j=1;j<=length($i);++j) 
        printf(" %s", substr($i, j, 1));
      if ((i < NF) && ($(i+1)!~"@")) printf(" <space>");
    }else{ 
      printf " "$i" ";
      if (i < NF) printf("<space>");
    }; 
  }
  printf("\n");
}' | sed 's/"/'\'' '\''/g;s/#/<stroke>/g' > char.val.txt

for f in $(<./test.lst); do grep "${f}\b" ${TextDir}/index.words; done |
awk '{
  printf("%s", $1);
  for(i=2;i<=NF;++i) {
    if($i!~"@"){  
      for(j=1;j<=length($i);++j) 
        printf(" %s", substr($i, j, 1));
      if ((i < NF) && ($(i+1)!~"@")) printf(" <space>");
    }else{ 
      printf " "$i" ";
      if (i < NF) printf("<space>");
    }; 
  }
  printf("\n");
}' | sed 's/"/'\'' '\''/g;s/#/<stroke>/g' > char.test.txt


#Symbols
for p in train test val; do cat char.${p}.txt | cut -f 2- -d\  | tr \  \\n; done | sort -u -V | awk 'BEGIN{
  N=0;
  printf("%-12s %d\n", "<ctc>", N++);
}NF==1{
  printf("%-12s %d\n", $1, N++);
}' >  symb.txt


cd ${WorkDir}
rm -rf ${ModelDir}
mkdir ${ModelDir}

#Creation of the optical model.
pylaia-htr-create-model \
  --print_args True \
  --train_path ${ModelDir} \
  --model_filename model \
  --logging_level info \
  --fixed_input_height 0 \
  --cnn_kernel_size 3 3 3 3 \
  --adaptive_pooling "avgpool-16" \
  --cnn_dilation 1 1 1 1 \
  --cnn_num_features 16 32 64 96 \
  --cnn_batchnorm True True True True \
  --cnn_activations LeakyReLU LeakyReLU LeakyReLU LeakyReLU \
  --cnn_poolsize 2 2 0 2  \
  --use_masked_conv=true \
  --rnn_type LSTM \
  --rnn_layers 3 \
  --rnn_units 256 \
  --rnn_dropout 0.5 \
  --lin_dropout 0.5 \
  3 ${TmpDir}/symb.txt

#--cnn_num_features 16 32 64 96 \

#Optical model entertainment.
pylaia-htr-train-ctc-rgb \
  --print_args TRUE --gpu ${GPU} \
  --train_path ${ModelDir} --model_filename model \
  --use_baidu_ctc=true \
  --add_logsoftmax_to_loss=false \
  --logging_level info \
  --logging_also_to_stderr info \
  --logging_file train-crnn.log \
  --show_progress_bar True \
  --batch_size ${BatchSize} \
  --learning_rate 0.0003 \
  --use_distortions True \
  --max_nondecreasing_epochs 50 \
  --delimiters="<space>" \
  ${TmpDir}/symb.txt $img_dirs ${TmpDir}/char.train.txt ${TmpDir}/char.val.txt
#syms img_dirs [img_dirs...] tr_txt_table va_txt_table



mkdir ${TmpDir}/decode
cd ${TmpDir}/decode 

#Decodification Test and Val for Wer
#CER (SPACE = "<SPACE>", JOIN_STR = " ")
pylaia-htr-decode-ctc-rgb \
  --print_args True \
  --gpu ${GPU} \
  --train_path ${ModelDir} \
  --model_filename model \
  --logging_level info \
  --logging_also_to_stderr info \
  --logging_file test-crnn.log \
  --batch_size ${BatchSize} \
  --print_img_ids \
  --use_letters \
  --separator=" " \
  --space "<space>" \
  --join_str " " \
  ${TmpDir}/symb.txt $img_dirs ${TmpDir}/test.lst > ${TmpDir}/decode/test.txt

pylaia-htr-decode-ctc-rgb \
  --print_args True \
  --gpu ${GPU} \
  --train_path ${ModelDir} \
  --model_filename model \
  --logging_level info \
  --logging_also_to_stderr info \
  --logging_file test-crnn.log \
  --batch_size ${BatchSize} \
  --print_img_ids \
  --use_letters \
  --separator=" " \
  --space "<space>" \
  --join_str " " \
  ${TmpDir}/symb.txt $img_dirs ${TmpDir}/val.lst > ${TmpDir}/decode/va.txt


# Get word-level transcript hypotheses (WER)
awk '{
  printf("%s ", $1);
  for (i=2;i<=NF;++i) {
    if ($i == "<space>")
      printf(" ");
    else
      printf("%s", $i);
  }
  printf("\n");
}' ${TmpDir}/decode/test.txt > ${TmpDir}/decode/wordtest.txt;

awk '{
  printf("%s ", $1);
  for (i=2;i<=NF;++i) {
    if ($i == "<space>")
      printf(" ");
    else
      printf("%s", $i);
  }
  printf("\n");
}' ${TmpDir}/decode/va.txt > ${TmpDir}/decode/wordva.txt;

cd ${CharDir}

awk '{
  printf("%s ", $1);
  for (i=2;i<=NF;++i) {
    if ($i == "<space>")
      printf(" ");
    else
      printf("%s", $i);
  }
  printf("\n");
}' char.total.txt > word.total.txt;


# Compute CER/WER.
cd ${TmpDir}/decode
if $(which compute-wer &> /dev/null); then
  #CER
  echo "test" > $WorkDir/alt_not_parenthesized_res_exp.txt
  compute-wer --mode=present ark:${CharDir}/char.total.txt ark:${TmpDir}/decode/test.txt | grep WER | sed -r 's|%WER|%CER|g' >> $WorkDir/alt_not_parenthesized_res_exp.txt
  echo "val" >> $WorkDir/alt_not_parenthesized_res_exp.txt
  compute-wer --mode=present ark:${CharDir}/char.total.txt ark:${TmpDir}/decode/va.txt | grep WER | sed -r 's|%WER|%CER|g' >> $WorkDir/alt_not_parenthesized_res_exp.txt

  #WER
  echo "test" >> $WorkDir/alt_not_parenthesized_res_exp.txt
  compute-wer --mode=present  ark:${CharDir}/word.total.txt ark:${TmpDir}/decode/wordtest.txt |  grep WER >> $WorkDir/alt_not_parenthesized_res_exp.txt
  echo "val" >> $WorkDir/alt_not_parenthesized_res_exp.txt
  compute-wer --mode=present  ark:${CharDir}/word.total.txt ark:${TmpDir}/decode/wordva.txt |  grep WER >> $WorkDir/alt_not_parenthesized_res_exp.txt

  echo "------------" >> $WorkDir/alt_not_parenthesized_res_exp.txt

  sed 's/\([.,:;?]\)/ \1/g;s/\([¿¡]\)/\1 /g' wordtest.txt > SeparateSimbols-wordtest.txt
  #sed 's/\([.,:;?]\)/ \1/g;s/\([¿¡]\)/\1 /g' corrected_wordtest.txt > SeparateSimbols-corrected_wordtest.txt
  sed 's/\([.,:;?]\)/ \1/g;s/\([¿¡]\)/\1 /g' wordva.txt > SeparateSimbols-wordva.txt
  sed 's/\([.,:;?]\)/ \1/g;s/\([¿¡]\)/\1 /g' ${CharDir}/word.total.txt > SeparateSimbols-word.txt
  sed 's/ \.line/\.line/g;s/ \.r\([0-9]\)/\.r\1/g' -i SeparateSimbols-word.txt
  sed 's/ \.line/\.line/g;s/ \.r\([0-9]\)/\.r\1/g' -i SeparateSimbols-wordtest.txt
  #sed 's/ \.line/\.line/g;s/ \.r\([0-9]\)/\.r\1/g' -i SeparateSimbols-corrected_wordtest.txt
  sed 's/ \.line/\.line/g;s/ \.r\([0-9]\)/\.r\1/g' -i SeparateSimbols-wordva.txt

  sed 's/</ </g;s/>/> /g' SeparateSimbols-word.txt | sed 's/  / /g' > k; mv k SeparateSimbols-word.txt
  sed 's/</ </g;s/>/> /g' SeparateSimbols-wordtest.txt | sed 's/  / /g' > k; mv k SeparateSimbols-wordtest.txt
  #sed 's/</ </g;s/>/> /g' SeparateSimbols-corrected_wordtest.txt | sed 's/  / /g' > k; mv k SeparateSimbols-corrected_wordtest.txt
  sed 's/</ </g;s/>/> /g' SeparateSimbols-wordva.txt | sed 's/  / /g' > k; mv k SeparateSimbols-wordva.txt

  #Wer calculation with the separation of the characters above ^ (Hello! -> Hello!)
  compute-wer --mode=present ark:SeparateSimbols-word.txt ark:SeparateSimbols-wordtest.txt >> $WorkDir/alt_not_parenthesized_res_exp.txt
  echo "------------" >> $WorkDir/alt_not_parenthesized_res_exp.txt
  compute-wer --mode=present ark:SeparateSimbols-word.txt ark:SeparateSimbols-wordva.txt >> $WorkDir/alt_not_parenthesized_res_exp.txt
  echo "------------" >> $WorkDir/alt_not_parenthesized_res_exp.txt

  #WER with tagging fix
  python $ScriptsDir/fix_separate_symb_output.py $TmpDir/decode/SeparateSimbols-wordtest.txt $TmpDir/decode/fixed_SeparateSimbols-wordtest.txt
  python $ScriptsDir/fix_separate_symb_output.py $TmpDir/decode/SeparateSimbols-word.txt $TmpDir/decode/fixed_SeparateSimbols-word.txt
  python $ScriptsDir/fix_separate_symb_output.py $TmpDir/decode/SeparateSimbols-wordva.txt $TmpDir/decode/fixed_SeparateSimbols-wordva.txt  

  compute-wer --mode=present ark:fixed_SeparateSimbols-word.txt ark:fixed_SeparateSimbols-wordtest.txt >> $WorkDir/alt_not_parenthesized_res_exp.txt
  echo "------------" >> $WorkDir/alt_not_parenthesized_res_exp.txt
  compute-wer --mode=present ark:fixed_SeparateSimbols-word.txt ark:fixed_SeparateSimbols-wordva.txt >> $WorkDir/alt_not_parenthesized_res_exp.txt
  echo "------------" >> $WorkDir/alt_not_parenthesized_res_exp.txt


  # rm Separate*

else
  echo "ERROR: Kaldi's compute-wer was not found in your PATH!" >&2;
fi;


######################################################################################################
## NER GT

cd ${WorkDir}

mkdir ${NerDir}
cd ${NerDir}
$ScriptsDir/extractNER-GT_GW.sh ${TextDir}/index.words 

cd -
mkdir ${NerNoRepDir}
cd ${NerNoRepDir}
$ScriptsDir/extractNER-GT-noRep.sh ${TextDir}/index.words


########################################################################################################################
################# Language Model  ######################################################################################
########################################################################################################################

# Force alignment

# Obtaining confMats
cd ${TmpDir}/decode

pylaia-htr-netout-rgb \
 --show_progress_bar True \
 --print_args True \
 --train_path ${ModelDir} \
 --model_filename model \
 --logging_level info \
 --logging_also_to_stderr info \
 --logging_file CMs-crnn.log  \
 --batch_size ${BatchSize} \
 --output_transform log_softmax \
 --output_matrix confMats_ark-test.txt \
 $img_dirs ${TmpDir}/test.lst

pylaia-htr-netout-rgb \
 --show_progress_bar True \
 --print_args True \
 --train_path ${ModelDir} \
 --model_filename model \
 --logging_level info \
 --logging_also_to_stderr info \
 --logging_file CMs-crnn.log  \
 --batch_size ${BatchSize} \
 --output_transform log_softmax \
 --output_matrix confMats_ark-validation.txt \
 $img_dirs ${TmpDir}/val.lst

awk '{print $1}' ${TmpDir}/symb.txt > ${TmpDir}/decode/chars.lst


#Processing development feature samples into Kaldi format
########################Y###################################################################################
mkdir -p $TmpDir/decode/test

copy-matrix "ark,t:confMats_ark-validation.txt" "ark,scp:test/confMats_alp0.3-validation.ark,test/confMats_alp0.3-validation.scp"
copy-matrix "ark,t:confMats_ark-test.txt" "ark,scp:test/confMats_alp0.3-test.ark,test/confMats_alp0.3-test.scp"

# Prepare Kaldi's lang directories
############################################################################################################
# Preparing Lexic (L)
cd ${LangDir}
mkdir lm

cp $TmpDir/decode/chars.lst ./chars.lst
#awk 'NR>1{print $1}' ./char/symb.txt > chars.lst



BLANK_SYMB="<ctc>"                        # BLSTM non-character symbol
WHITESPACE_SYMB="<space>"                 # White space symbol
DUMMY_CHAR="<DUMMY>"                      # Especial HMM used for modelling "</s>" end-sentence

$ScriptsDir/prepare_lang_cl-ds.sh lm ./chars.lst "${BLANK_SYMB}" "${WHITESPACE_SYMB}" "${DUMMY_CHAR}"

cd lm/

# Preparing LM (G)

for f in $(<${PartDir}/train.lst); do
 nn=`basename ${f/.png/}`; grep $nn ../char/char.total.txt;
done | cut -d " " -f 2- | ngram-count -vocab ../chars.lst -text - -lm lang/LM.arpa -order 8 -wbdiscount1 -kndiscount -interpolate

$ScriptsDir/prepare_lang_test-ds.sh lang/LM.arpa lang lang_test "$DUMMY_CHAR"

# python $ScriptsDir/generate_categorical_sfsa_gw.py $LangDir/lm/lang/phones.txt $WorkDir/CAT_FST/Categorical.fst
# $ScriptsDir/prepare_lang_test_categorical.sh $WorkDir/CAT_FST/Categorical.fst lang lang_test "$DUMMY_CHAR"


##########################################################################################################
# Prepare HMM models
##########################################################################################################
# Create HMM topology file
cd $ModelDir
mkdir -p HMMs/train
ln -s $TmpDir/decode/test/ .

phones_list=( $(cat ${LangDir}/lm/lang_test/phones/{,non}silence.int) )
featdim=$(feat-to-dim scp:test/confMats_alp0.3-test.scp - 2>/dev/null)
dummyID=$(awk -v d="$DUMMY_CHAR" '{if (d==$1) print $2}' ${LangDir}/lm/lang/phones.txt)
blankID=$(awk -v bs="${BLANK_SYMB}" '{if (bs==$1) print $2}' ${LangDir}/lm/lang/pdf_blank.txt)

HMM_LOOP_PROB=0.5                         # Self-Loop HMM-state probability
HMM_NAC_PROB=0.5                          # BLSTM-NaC HMM-state probability

$ScriptsDir/create_proto_rnn-ds.sh $featdim ${HMM_LOOP_PROB} ${HMM_NAC_PROB} HMMs/train ${dummyID} ${blankID} ${phones_list[@]}





# Compose FSTs
############################################################################################################

mkdir HMMs/test
$ScriptsDir/mkgraph.sh --mono --transition-scale 1.0 --self-loop-scale 1.0 $LangDir/lm/lang_test HMMs/train/new.mdl HMMs/train/new.tree HMMs/test/graph

############################################################################################################



# Lattice Generation
############################################################################################################
cd $TmpDir/decode
mkdir lattices

ASF=0.818485839158                        # Acoustic Scale Factor
MAX_NUM_ACT_STATES=2007483647             # Maximum number of active states
BEAM_SEARCH=15                            # Beam search
LATTICE_BEAM=12                           # Lattice generation beam
N_CORES=1     

latgen-faster-mapped --verbose=2 --allow-partial=true --acoustic-scale=${ASF} --max-active=${MAX_NUM_ACT_STATES} --beam=${BEAM_SEARCH} --lattice-beam=${LATTICE_BEAM} --max-mem=4194304 $ModelDir/HMMs/train/new.mdl $ModelDir/HMMs/test/graph/HCLG.fst scp:test/confMats_alp0.3-test.scp "ark:|gzip -c > lattices/lat-test.gz" ark,t:lattices/RES-test 2>lattices/LOG-Lats-test
latgen-faster-mapped --verbose=2 --allow-partial=true --acoustic-scale=${ASF} --max-active=${MAX_NUM_ACT_STATES} --beam=${BEAM_SEARCH} --lattice-beam=${LATTICE_BEAM} --max-mem=4194304 $ModelDir/HMMs/train/new.mdl $ModelDir/HMMs/test/graph/HCLG.fst scp:test/confMats_alp0.3-validation.scp "ark:|gzip -c > lattices/lat-validation.gz" ark,t:lattices/RES-validation 2>lattices/LOG-Lats-validation


# Final Evaluation
###########################################################################################################
ASF=1.39176532 
WIP=-1.16902908

cd lattices

$ScriptsDir/score.sh --wip $WIP --lmw $ASF $ModelDir/HMMs/test/graph/words.txt "ark:gzip -c -d lat-test.gz |" $LangDir/char/char.total.txt hypotheses-test 2>log
$ScriptsDir/score.sh --wip $WIP --lmw $ASF $ModelDir/HMMs/test/graph/words.txt "ark:gzip -c -d lat-validation.gz |" $LangDir/char/char.total.txt hypotheses-validation 2>log




simplex.py -v -m "${ScriptsDir}/opt_gsf-wip_cl.sh {$ASF} {$WIP}" > result-simplex

ASF=1.27216049 
WIP=-0.76260881

$ScriptsDir/score.sh --wip $WIP --lmw $ASF $ModelDir/HMMs/test/graph/words.txt "ark:gzip -c -d lat-test.gz |" $LangDir/char/char.total.txt hypotheses-test 2>log


# Pass the category language model and generate output
# lattice-lmrescore --lm-scale=1.0 "ark:gzip -c -d lat-test.gz |" ${LangDir}/lm/lang_test/G_cat.fst "ark:|gzip -c > rescored_lat-test.gz"
# lattice-lmrescore --lm-scale=1.0 "ark:gzip -c -d lat-validation.gz |" ${LangDir}/lm/lang_test/G_cat.fst "ark:|gzip -c > rescored_lat-validation.gz"
# $ScriptsDir/score.sh --wip $WIP --lmw $ASF $ModelDir/HMMs/test/graph/words.txt "ark:gzip -c -d rescored_lat-test.gz |" $LangDir/char/char.total.txt rescored_hypotheses-test 2>log
# $ScriptsDir/score.sh --wip $WIP --lmw $ASF $ModelDir/HMMs/test/graph/words.txt "ark:gzip -c -d rescored_lat-validation.gz |" $LangDir/char/char.total.txt rescored_hypotheses-validation 2>log

# Rescoring Latice -> Pass language model -> generate output (somewhat worse results)
# lattice-scale --acoustic-scale=${ASF} "ark:gzip -c -d lat-test.gz |" ark:- | \
# lattice-add-penalty --word-ins-penalty=${WIP} ark:- ark:- | \
# lattice-lmrescore --lm-scale=1.0 ark:- ${LangDir}/lm/lang_test/G_cat.fst "ark:|gzip -c > rescored_lat-test.gz"
# lattice-best-path "ark:gzip -c -d rescored_lat-test.gz |" ark,t:rescored_hypotheses-test

# lattice-scale --acoustic-scale=${ASF} "ark:gzip -c -d lat-validation.gz |" ark:- | \
# lattice-add-penalty --word-ins-penalty=${WIP} ark:- ark:- | \
# lattice-lmrescore --lm-scale=1.0 ark:- ${LangDir}/lm/lang_test/G_cat.fst "ark:|gzip -c > rescored_lat-validation.gz"
# lattice-best-path "ark:gzip -c -d rescored_lat-validation.gz |" ark,t:rescored_hypotheses-validation

echo -e "\nGenerating file of hypotheses: hypotheses_t" 1>&2
int2sym.pl -f 2- $LangDir/lm/lang_test/words.txt hypotheses-test > hypotheses-test_t
int2sym.pl -f 2- $LangDir/lm/lang_test/words.txt hypotheses-validation > hypotheses-validation_t

# int2sym.pl -f 2- $LangDir/lm/lang_test/words.txt rescored_hypotheses-test > rescored_hypotheses-test_t
# int2sym.pl -f 2- $LangDir/lm/lang_test/words.txt rescored_hypotheses-validation > rescored_hypotheses-validation_t


# Recombine the outputs to take the Output of the Rescored and the other in case of doubt
# python $ScriptsDir/combine_hypotheses_files.py rescored_hypotheses-test_t hypotheses-test_t combined_hypotheses-test_t
# python $ScriptsDir/combine_hypotheses_files.py rescored_hypotheses-validation_t hypotheses-validation_t combined_hypotheses-validation_t 

############################################################################################################

mkdir word-lm

# Get word-level transcript hypotheses
awk '{
  printf("%s ", $1);
  for (i=2;i<=NF;++i) {
    if ($i == "<space>")
      printf(" ");
    else
      printf("%s", $i);
  }
  printf("\n");
}' hypotheses-test_t > word-lm/hyp_word-test.txt;

awk '{
  printf("%s ", $1);
  for (i=2;i<=NF;++i) {
    if ($i == "<space>")
      printf(" ");
    else
      printf("%s", $i);
  }
  printf("\n");
}' hypotheses-validation_t > word-lm/hyp_word-validation.txt;

# awk '{
#   printf("%s ", $1);
#   for (i=2;i<=NF;++i) {
#     if ($i == "<space>")
#       printf(" ");
#     else
#       printf("%s", $i);
#   }
#   printf("\n");
# }' combined_hypotheses-test_t > word-lm/combined_hyp_word-test.txt;

# awk '{
#   printf("%s ", $1);
#   for (i=2;i<=NF;++i) {
#     if ($i == "<space>")
#       printf(" ");
#     else
#       printf("%s", $i);
#   }
#   printf("\n");
# }' combined_hypotheses-validation_t > word-lm/combined_hyp_word-validation.txt;


#Align output to generate hypothesis with transcription from 1-best and correct tagging
# python $ScriptsDir/align_hypotheses.py word-lm/hyp_word-validation.txt word-lm/combined_hyp_word-validation.txt \
# word-lm/aligned_hypotheses-validation.txt

# python $ScriptsDir/align_hypotheses.py word-lm/hyp_word-test.txt word-lm/combined_hyp_word-test.txt \
# word-lm/aligned_hypotheses-test.txt

# python $ScriptsDir/align_hypotheses.py hypotheses-validation_t  combined_hypotheses-validation_t  \
# aligned_hypotheses-validation_t > log.txt

# python $ScriptsDir/align_hypotheses.py hypotheses-test_t combined_hypotheses-test_t \
# aligned_hypotheses-test_t > log.txt

# #ALIGNMENT AT WORD LEVEL
# python $ScriptsDir/align_hypotheses_wer.py hypotheses-validation_t  combined_hypotheses-validation_t  \
# wer_aligned_hypotheses-validation_t > log.txt

# python $ScriptsDir/align_hypotheses_wer.py hypotheses-test_t combined_hypotheses-test_t \
# wer_aligned_hypotheses-test_t > log.txt


# awk '{
#   printf("%s ", $1);
#   for (i=2;i<=NF;++i) {
#     if ($i == "<space>")
#       printf(" ");
#     else
#       printf("%s", $i);
#   }
#   printf("\n");
# }' aligned_hypotheses-test_t > word-lm/aligned_hyp_word-test.txt;

# awk '{
#   printf("%s ", $1);
#   for (i=2;i<=NF;++i) {
#     if ($i == "<space>")
#       printf(" ");
#     else
#       printf("%s", $i);
#   }
#   printf("\n");
# }' aligned_hypotheses-validation_t  > word-lm/aligned_hyp_word-validation.txt;

# awk '{
#   printf("%s ", $1);
#   for (i=2;i<=NF;++i) {
#     if ($i == "<space>")
#       printf(" ");
#     else
#       printf("%s", $i);
#   }
#   printf("\n");
# }' wer_aligned_hypotheses-test_t > word-lm/wer_aligned_hyp_word-test.txt;

# awk '{
#   printf("%s ", $1);
#   for (i=2;i<=NF;++i) {
#     if ($i == "<space>")
#       printf(" ");
#     else
#       printf("%s", $i);
#   }
#   printf("\n");
# }' wer_aligned_hypotheses-validation_t  > word-lm/wer_aligned_hyp_word-validation.txt;


echo "==============" >> $WorkDir/alt_not_parenthesized_res_exp.txt
echo "Results after adding LM" >> $WorkDir/alt_not_parenthesized_res_exp.txt

#cd $TmpDir/decode/
#Compute CER/WER.
if $(which compute-wer &> /dev/null); then
  echo "Test cer" >> $WorkDir/alt_not_parenthesized_res_exp.txt
  compute-wer --mode=present  ark:$LangDir/char/char.total.txt ark:hypotheses-test_t | grep WER | sed -r 's|%WER|%CER|g' >> $WorkDir/alt_not_parenthesized_res_exp.txt;
  echo "Test wer" >> $WorkDir/alt_not_parenthesized_res_exp.txt
  compute-wer --mode=present  ark:$LangDir/char/word.total.txt ark:word-lm/hyp_word-test.txt |  grep WER >> $WorkDir/alt_not_parenthesized_res_exp.txt;

  # echo "Test cer (COMBINED)" >> $WorkDir/alt_not_parenthesized_res_exp.txt
  # compute-wer --mode=present  ark:$LangDir/char/char.total.txt ark:combined_hypotheses-test_t | grep WER | sed -r 's|%WER|%CER|g' >> $WorkDir/alt_not_parenthesized_res_exp.txt;
  # echo "Test wer (COMBINED)" >> $WorkDir/alt_not_parenthesized_res_exp.txt
  # compute-wer --mode=present  ark:$LangDir/char/word.total.txt ark:word-lm/combined_hyp_word-test.txt |  grep WER >> $WorkDir/alt_not_parenthesized_res_exp.txt;

  # echo "Test cer (ALIGNED)" >> $WorkDir/alt_not_parenthesized_res_exp.txt
  # compute-wer --mode=present  ark:$LangDir/char/char.total.txt ark:aligned_hypotheses-test_t | grep WER | sed -r 's|%WER|%CER|g' >> $WorkDir/alt_not_parenthesized_res_exp.txt;
  # echo "Test wer (ALIGNED)" >> $WorkDir/alt_not_parenthesized_res_exp.txt
  # compute-wer --mode=present  ark:$LangDir/char/word.total.txt ark:word-lm/aligned_hyp_word-test.txt |  grep WER >> $WorkDir/alt_not_parenthesized_res_exp.txt;

  # echo "Test cer (WER ALIGNED)" >> $WorkDir/alt_not_parenthesized_res_exp.txt
  # compute-wer --mode=present  ark:$LangDir/char/char.total.txt ark:wer_aligned_hypotheses-test_t | grep WER | sed -r 's|%WER|%CER|g' >> $WorkDir/alt_not_parenthesized_res_exp.txt;
  # echo "Test wer (WER ALIGNED)" >> $WorkDir/alt_not_parenthesized_res_exp.txt
  # compute-wer --mode=present  ark:$LangDir/char/word.total.txt ark:word-lm/wer_aligned_hyp_word-test.txt |  grep WER >> $WorkDir/alt_not_parenthesized_res_exp.txt;


  sed 's/\([.,:;?]\)/ \1/g;s/\([¿¡]\)/\1 /g' word-lm/hyp_word-test.txt > SeparateSimbols-wordtest.txt
  sed 's/\([.,:;?]\)/ \1/g;s/\([¿¡]\)/\1 /g' $LangDir/char/word.total.txt > SeparateSimbols-word.txt
  sed 's/ \.line/\.line/g;s/ \.r\([0-9]\)/\.r\1/g;s/ \.region/\.region/g' -i SeparateSimbols-word.txt
  sed 's/ \.line/\.line/g;s/ \.r\([0-9]\)/\.r\1/g;s/ \.region/\.region/g' -i SeparateSimbols-wordtest.txt
  sed 's/</ </g' SeparateSimbols-wordtest.txt | sed 's/>/> /g' | sed 's/  / /g' > k; mv k SeparateSimbols-wordtest.txt
  sed 's/</ </g' SeparateSimbols-word.txt | sed 's/>/> /g' | sed 's/  / /g' > k; mv k SeparateSimbols-word.txt

  

  echo "Test wer separate" >> $WorkDir/alt_not_parenthesized_res_exp.txt
  compute-wer --mode=present ark:SeparateSimbols-word.txt ark:SeparateSimbols-wordtest.txt >> $WorkDir/alt_not_parenthesized_res_exp.txt

  echo "Test wer separate (fixed)" >> $WorkDir/alt_not_parenthesized_res_exp.txt
  python $ScriptsDir/fix_separate_symb_output_alt.py $TmpDir/decode/lattices/SeparateSimbols-wordtest.txt $TmpDir/decode/lattices/fixed_SeparateSimbols-wordtest.txt
  python $ScriptsDir/fix_separate_symb_output_alt.py $TmpDir/decode/lattices/SeparateSimbols-word.txt $TmpDir/decode/lattices/fixed_SeparateSimbols-word.txt
  compute-wer --mode=present ark:fixed_SeparateSimbols-word.txt ark:fixed_SeparateSimbols-wordtest.txt >> $WorkDir/alt_not_parenthesized_res_exp.txt

  # sed 's/\([.,:;?]\)/ \1/g;s/\([¿¡]\)/\1 /g' word-lm/combined_hyp_word-test.txt > SeparateSimbols-wordtest.txt
  # sed 's/ \.line/\.line/g;s/ \.r\([0-9]\)/\.r\1/g' -i SeparateSimbols-wordtest.txt
  # sed 's/</ </g' SeparateSimbols-wordtest.txt | sed 's/>/> /g' | sed 's/  / /g' > k; mv k SeparateSimbols-wordtest.txt

  # echo "Test wer separate (COMBINED)" >> $WorkDir/alt_not_parenthesized_res_exp.txt
  # compute-wer --mode=present ark:SeparateSimbols-word.txt ark:SeparateSimbols-wordtest.txt >> $WorkDir/alt_not_parenthesized_res_exp.txt

  # sed 's/\([.,:;?]\)/ \1/g;s/\([¿¡]\)/\1 /g' word-lm/aligned_hyp_word-test.txt > SeparateSimbols-wordtest.txt
  # sed 's/ \.line/\.line/g;s/ \.r\([0-9]\)/\.r\1/g' -i SeparateSimbols-wordtest.txt
  # sed 's/</ </g' SeparateSimbols-wordtest.txt | sed 's/>/> /g' | sed 's/  / /g' > k; mv k SeparateSimbols-wordtest.txt

  # echo "Test wer separate (ALIGNED)" >> $WorkDir/alt_not_parenthesized_res_exp.txt
  # compute-wer --mode=present ark:SeparateSimbols-word.txt ark:SeparateSimbols-wordtest.txt >> $WorkDir/alt_not_parenthesized_res_exp.txt

  # sed 's/\([.,:;?]\)/ \1/g;s/\([¿¡]\)/\1 /g' word-lm/wer_aligned_hyp_word-test.txt > SeparateSimbols-wordtest.txt
  # sed 's/ \.line/\.line/g;s/ \.r\([0-9]\)/\.r\1/g' -i SeparateSimbols-wordtest.txt
  # sed 's/</ </g' SeparateSimbols-wordtest.txt | sed 's/>/> /g' | sed 's/  / /g' > k; mv k SeparateSimbols-wordtest.txt

  # echo "Test wer separate (WER ALIGNED)" >> $WorkDir/alt_not_parenthesized_res_exp.txt
  # compute-wer --mode=present ark:SeparateSimbols-word.txt ark:SeparateSimbols-wordtest.txt >> $WorkDir/alt_not_parenthesized_res_exp.txt

  echo "--------------" >> $WorkDir/alt_not_parenthesized_res_exp.txt
  echo "Val cer" >> $WorkDir/alt_not_parenthesized_res_exp.txt
  compute-wer --mode=present  ark:$LangDir/char/char.total.txt ark:hypotheses-validation_t |   grep WER | sed -r 's|%WER|%CER|g' >> $WorkDir/alt_not_parenthesized_res_exp.txt;

  echo "Val wer" >> $WorkDir/alt_not_parenthesized_res_exp.txt
  compute-wer --mode=present  ark:$LangDir/char/word.total.txt ark:word-lm/hyp_word-validation.txt |  grep WER >> $WorkDir/alt_not_parenthesized_res_exp.txt;

  sed 's/\([.,:;?]\)/ \1/g;s/\([¿¡]\)/\1 /g' word-lm/hyp_word-validation.txt > SeparateSimbols-wordvalidation.txt
  sed 's/ \.line/\.line/g;s/ \.r\([0-9]\)/\.r\1/g' -i SeparateSimbols-wordvalidation.txt
  sed 's/</ </g' SeparateSimbols-wordvalidation.txt | sed 's/>/> /g' | sed 's/  / /g' > k; mv k SeparateSimbols-wordvalidation.txt

  echo "Val wer separate" >> $WorkDir/alt_not_parenthesized_res_exp.txt
  compute-wer --mode=present ark:SeparateSimbols-word.txt ark:SeparateSimbols-wordvalidation.txt >> $WorkDir/alt_not_parenthesized_res_exp.txt

  # rm Separate*

else
  echo "ERROR: Kaldi's compute-wer was not found in your PATH!" >&2;
fi;

##########################################################################
## ORACLE METRICS

# $ScriptsDir/oracle_transc.sh $TmpDir $LangDir/lm/lang $TmpDir/decode/lattices/

# int2sym.pl -f 2- $LangDir/lm/lang_test/words.txt $TmpDir/decode/lattices/oracle_transc.txt > $TmpDir/decode/lattices/oracle_transc_t

# #CALC CER WITH ORACLE_TRANSC
# echo "ORACLE CER" >> $WorkDir/alt_not_parenthesized_res_exp.txt
# compute-wer --mode=present  ark:$lang/../../char/char.total.txt ark:$TmpDir/decode/lattices/oracle_transc_t | grep WER | sed -r 's|%WER|%CER|g' >> $WorkDir/alt_not_parenthesized_res_exp.txt

# #CALC WER
# awk '{
#   printf("%s ", $1);
#   for (i=2;i<=NF;++i) {
#     if ($i == "<space>")
#       printf(" ");
#     else
#       printf("%s", $i);
#   }
#   printf("\n");
# }' $TmpDir/decode/lattices/oracle_transc_t > $TmpDir/decode/lattices/word-lm/oracle_transc-test.txt;

# sed 's/\([.,:;?]\)/ \1/g;s/\([¿¡]\)/\1 /g' $TmpDir/decode/lattices/word-lm/oracle_transc-test.txt > $TmpDir/decode/lattices/SeparateSimbols-wordtest.txt
# sed 's/ \.line/\.line/g;s/ \.r\([0-9]\)/\.r\1/g' -i $TmpDir/decode/lattices/SeparateSimbols-wordtest.txt
# sed 's/</ </g' $TmpDir/decode/lattices/SeparateSimbols-wordtest.txt | sed 's/>/> /g' | sed 's/  / /g' > k; mv k $TmpDir/decode/lattices/SeparateSimbols-wordtest.txt

# echo "ORACLE WER (SEPARATE)" >> $WorkDir/alt_not_parenthesized_res_exp.txt
# compute-wer --mode=present ark:$TmpDir/decode/lattices/SeparateSimbols-word.txt ark:$TmpDir/decode/lattices/SeparateSimbols-wordtest.txt >> $WorkDir/alt_not_parenthesized_res_exp.txt


##########################################################################
## Evaluation Precision - Recall
cd $TmpDir/decode/

# python $ScriptsDir/fix_separate_symb_output.py $TmpDir/decode/SeparateSimbols-wordtest.txt $TmpDir/decode/fixed_SeparateSimbols-wordtest.txt
# python $ScriptsDir/fix_separate_symb_output.py $TmpDir/decode/SeparateSimbols-word.txt $TmpDir/decode/fixed_SeparateSimbols-word.txt

cd $TmpDir
for f in $(<$PartDir/test.lst); do grep "${f}\b" ${TmpDir}/decode/lattices/fixed_SeparateSimbols-word.txt; done > ./fixed_SeparateSimbols-GT_test.txt

mkdir $WorkDir/PREC-REC
cd $WorkDir/PREC-REC/

rm -rf $WorkDir/PREC-REC/ALT_6_NOT_PARENTHESIZED_NER-GT
mkdir $WorkDir/PREC-REC/ALT_6_NOT_PARENTHESIZED_NER-GT
cd $WorkDir/PREC-REC/ALT_6_NOT_PARENTHESIZED_NER-GT
python $ScriptsDir/extract_ner_not_parenthesized_gw.py $TmpDir/fixed_SeparateSimbols-GT_test.txt ./
for f in *; do sed 's/^ //g' -i $f; done
cd ..

rm -rf $WorkDir/PREC-REC/ALT_6_NOT_PARENTHESIZED_NER-DECODE
mkdir $WorkDir/PREC-REC/ALT_6_NOT_PARENTHESIZED_NER-DECODE
cd $WorkDir/PREC-REC/ALT_6_NOT_PARENTHESIZED_NER-DECODE
python $ScriptsDir/extract_ner_not_parenthesized_gw.py $TmpDir/decode/lattices/fixed_SeparateSimbols-wordtest.txt ./
for f in *; do sed 's/^ //g' -i $f; done
cd ..

# ORACLE

# rm -rf $WorkDir/PREC-REC/ORACLE_NER
# mkdir $WorkDir/PREC-REC/ORACLE_NER
# cd $WorkDir/PREC-REC/ORACLE_NER
# $ScriptsDir/extractNERHip2.sh $TmpDir/decode/lattices/word-lm/oracle_transc-test.txt .
# for f in *; do sed 's/^ //g' -i $f; done

# cd ..

# mkdir $WorkDir/PREC-REC/NER-GT
# cd $WorkDir/PREC-REC/NER-GT
# $ScriptsDir/extractNER-GT_GW.sh $TmpDir/SeparateSimbols-GT_test.txt .
# for f in *; do sed 's/^ //g' -i $f; done

# cd ..

#NER NORMAL
cd $WorkDir/PREC-REC
python $ScriptsDir/calc_prec_rec.py ./ALT_6_NOT_PARENTHESIZED_NER-GT ./ALT_6_NOT_PARENTHESIZED_NER-DECODE >> $WorkDir/alt_not_parenthesized_res_exp.txt
python $ScriptsDir/alt_dist_edicion_custom_saturated.py ./ALT_6_NOT_PARENTHESIZED_NER-GT ./ALT_6_NOT_PARENTHESIZED_NER-DECODE >> $WorkDir/alt_not_parenthesized_res_exp.txt