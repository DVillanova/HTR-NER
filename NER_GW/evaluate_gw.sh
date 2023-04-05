#set -e
export LC_NUMERIC=C.UTF-8;

#Enable PyLaia
conda activate pylaia

#Variables in Docker
GPU=1
BatchSize=8
WorkDir=/root/directorioTrabajo/DOC-NER/HTR-NER/NER_GW/
ScriptsDir=/root/directorioTrabajo/DOC-NER/HTR-NER/scripts/
PartDir=${WorkDir}/PARTITIONS
DataDir=${WorkDir}/washingtondb-v1.0/
img_dirs=${DataDir}/data/line_images_normalized/

###################################
#Evaluate parenthesized notation
cd $WorkDir
echo "==============================" > $WorkDir/results_gw.txt
echo "Results parenthesized notation" >> $WorkDir/results_gw.txt
echo "==============================" >> $WorkDir/results_gw.txt
#Variables for the exp
TextDir=${WorkDir}/TEXT
LangDir=${WorkDir}/lang
CharDir=${LangDir}/char
ModelDir=${WorkDir}/model
TmpDir=${WorkDir}/TMP

#CER / WER without tags (tagging_symb.txt must be generated beforehand)
python $ScriptsDir/remove_tagging.py $TmpDir/tagging_symb.txt \
$TmpDir/decode/lattices/hypotheses-test_t $TmpDir/decode/lattices/not_tagged_hypotheses-test_t

python $ScriptsDir/remove_tagging.py $TmpDir/tagging_symb.txt \
$LangDir/char/char.total.txt $LangDir/char/not_tagged_char.total.txt

#Generate word-level transc without tags
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
}' not_tagged_char.total.txt > not_tagged_word.total.txt;

cd $TmpDir/decode/lattices/
awk '{
  printf("%s ", $1);
  for (i=2;i<=NF;++i) {
    if ($i == "<space>")
      printf(" ");
    else
      printf("%s", $i);
  }
  printf("\n");
}' not_tagged_hypotheses-test_t > word-lm/not_tagged_hypotheses_word-test.txt;

sed 's/\([.,:;?]\)/ \1/g;s/\([¿¡]\)/\1 /g' word-lm/not_tagged_hypotheses_word-test.txt > not_tagged_SeparateSimbols-wordtest.txt
sed 's/\([.,:;?]\)/ \1/g;s/\([¿¡]\)/\1 /g' $LangDir/char/not_tagged_word.total.txt > not_tagged_SeparateSimbols-word.txt
sed 's/ \.line/\.line/g;s/ \.r\([0-9]\)/\.r\1/g;s/ \.region/\.region/g' -i not_tagged_SeparateSimbols-word.txt
sed 's/ \.line/\.line/g;s/ \.r\([0-9]\)/\.r\1/g;s/ \.region/\.region/g' -i not_tagged_SeparateSimbols-wordtest.txt
sed 's/</ </g' not_tagged_SeparateSimbols-wordtest.txt | sed 's/>/> /g' | sed 's/  / /g' > k; mv k not_tagged_SeparateSimbols-wordtest.txt
sed 's/</ </g' not_tagged_SeparateSimbols-word.txt | sed 's/>/> /g' | sed 's/  / /g' > k; mv k not_tagged_SeparateSimbols-word.txt

#Calculate CER / WER
echo "CER not tagged" >> $WorkDir/results_gw.txt
compute-wer --mode=present ark:${CharDir}/not_tagged_char.total.txt ark:${TmpDir}/decode/lattices/not_tagged_hypotheses-test_t | grep WER | sed -r 's|%WER|%CER|g' >> $WorkDir/results_gw.txt

echo "Separate WER not tagged" >> $WorkDir/results_gw.txt
compute-wer --mode=present ark:not_tagged_SeparateSimbols-word.txt ark:not_tagged_SeparateSimbols-wordtest.txt >> $WorkDir/results_gw.txt

#Macro P/R/F1 at line-level 
python $ScriptsDir/macro_edit_dist_tag_f1.py $TmpDir/tagging_symb.txt $TmpDir/test.lst \
$WorkDir/PREC-REC/CONTINUOUS_NER-GT/ $WorkDir/PREC-REC/CONTINUOUS_NER-DECODE/ >> $WorkDir/results_gw.txt

###################################
#Evaluate cont notation with reject class
cd $WorkDir
echo "==============================" >> $WorkDir/results_gw.txt
echo "Results NOT parenthesized notation (WITH REJECT)" >> $WorkDir/results_gw.txt
echo "==============================" >> $WorkDir/results_gw.txt
#Variables for the exp
TextDir=${WorkDir}/NOT_PARENTHESIZED_TEXT
LangDir=${WorkDir}/NOT_PARENTHESIZED_lang
CharDir=${LangDir}/char
ModelDir=${WorkDir}/NOT_PARENTHESIZED_model
TmpDir=${WorkDir}/NOT_PARENTHESIZED_TMP

#CER / WER without tags (tagging_symb.txt must be generated beforehand)
python $ScriptsDir/remove_tagging.py $TmpDir/tagging_symb.txt \
$TmpDir/decode/lattices/hypotheses-test_t $TmpDir/decode/lattices/not_tagged_hypotheses-test_t

python $ScriptsDir/remove_tagging.py $TmpDir/tagging_symb.txt \
$LangDir/char/char.total.txt $LangDir/char/not_tagged_char.total.txt

#Generate word-level transc without tags
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
}' not_tagged_char.total.txt > not_tagged_word.total.txt;

cd $TmpDir/decode/lattices/
awk '{
  printf("%s ", $1);
  for (i=2;i<=NF;++i) {
    if ($i == "<space>")
      printf(" ");
    else
      printf("%s", $i);
  }
  printf("\n");
}' not_tagged_hypotheses-test_t > word-lm/not_tagged_hypotheses_word-test.txt;

sed 's/\([.,:;?]\)/ \1/g;s/\([¿¡]\)/\1 /g' word-lm/not_tagged_hypotheses_word-test.txt > not_tagged_SeparateSimbols-wordtest.txt
sed 's/\([.,:;?]\)/ \1/g;s/\([¿¡]\)/\1 /g' $LangDir/char/not_tagged_word.total.txt > not_tagged_SeparateSimbols-word.txt
sed 's/ \.line/\.line/g;s/ \.r\([0-9]\)/\.r\1/g;s/ \.region/\.region/g' -i not_tagged_SeparateSimbols-word.txt
sed 's/ \.line/\.line/g;s/ \.r\([0-9]\)/\.r\1/g;s/ \.region/\.region/g' -i not_tagged_SeparateSimbols-wordtest.txt
sed 's/</ </g' not_tagged_SeparateSimbols-wordtest.txt | sed 's/>/> /g' | sed 's/  / /g' > k; mv k not_tagged_SeparateSimbols-wordtest.txt
sed 's/</ </g' not_tagged_SeparateSimbols-word.txt | sed 's/>/> /g' | sed 's/  / /g' > k; mv k not_tagged_SeparateSimbols-word.txt

#Calculate CER / WER
echo "CER not tagged" >> $WorkDir/results_gw.txt
compute-wer --mode=present ark:${CharDir}/not_tagged_char.total.txt ark:${TmpDir}/decode/lattices/not_tagged_hypotheses-test_t | grep WER | sed -r 's|%WER|%CER|g' >> $WorkDir/results_gw.txt

echo "Separate WER not tagged" >> $WorkDir/results_gw.txt
compute-wer --mode=present ark:not_tagged_SeparateSimbols-word.txt ark:not_tagged_SeparateSimbols-wordtest.txt >> $WorkDir/results_gw.txt


#Macro P/R/F1 at line-level 
python $ScriptsDir/macro_edit_dist_tag_f1.py $TmpDir/tagging_symb.txt $TmpDir/test.lst \
$WorkDir/PREC-REC/NOT_PARENTHESIZED_NER-GT/ $WorkDir/PREC-REC/NOT_PARENTHESIZED_NER-DECODE/ >> $WorkDir/results_gw.txt

###################################
#Evaluate cont notation without reject class
cd $WorkDir
echo "==============================" >> $WorkDir/results_gw.txt
echo "Results NOT parenthesized notation (WITHOUT REJECT)" >> $WorkDir/results_gw.txt
echo "==============================" >> $WorkDir/results_gw.txt
#Variables for the exp
TextDir=${WorkDir}/ALT_NOT_PARENTHESIZED_TEXT
LangDir=${WorkDir}/ALT_NOT_PARENTHESIZED_lang
CharDir=${LangDir}/char
ModelDir=${WorkDir}/ALT_NOT_PARENTHESIZED_model
TmpDir=${WorkDir}/ALT_NOT_PARENTHESIZED_TMP


#CER / WER without tags (tagging_symb.txt must be generated beforehand)
python $ScriptsDir/remove_tagging.py $TmpDir/tagging_symb.txt \
$TmpDir/decode/lattices/hypotheses-test_t $TmpDir/decode/lattices/not_tagged_hypotheses-test_t

python $ScriptsDir/remove_tagging.py $TmpDir/tagging_symb.txt \
$LangDir/char/char.total.txt $LangDir/char/not_tagged_char.total.txt

#Generate word-level transc without tags
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
}' not_tagged_char.total.txt > not_tagged_word.total.txt;

cd $TmpDir/decode/lattices/
awk '{
  printf("%s ", $1);
  for (i=2;i<=NF;++i) {
    if ($i == "<space>")
      printf(" ");
    else
      printf("%s", $i);
  }
  printf("\n");
}' not_tagged_hypotheses-test_t > word-lm/not_tagged_hypotheses_word-test.txt;

sed 's/\([.,:;?]\)/ \1/g;s/\([¿¡]\)/\1 /g' word-lm/not_tagged_hypotheses_word-test.txt > not_tagged_SeparateSimbols-wordtest.txt
sed 's/\([.,:;?]\)/ \1/g;s/\([¿¡]\)/\1 /g' $LangDir/char/not_tagged_word.total.txt > not_tagged_SeparateSimbols-word.txt
sed 's/ \.line/\.line/g;s/ \.r\([0-9]\)/\.r\1/g;s/ \.region/\.region/g' -i not_tagged_SeparateSimbols-word.txt
sed 's/ \.line/\.line/g;s/ \.r\([0-9]\)/\.r\1/g;s/ \.region/\.region/g' -i not_tagged_SeparateSimbols-wordtest.txt
sed 's/</ </g' not_tagged_SeparateSimbols-wordtest.txt | sed 's/>/> /g' | sed 's/  / /g' > k; mv k not_tagged_SeparateSimbols-wordtest.txt
sed 's/</ </g' not_tagged_SeparateSimbols-word.txt | sed 's/>/> /g' | sed 's/  / /g' > k; mv k not_tagged_SeparateSimbols-word.txt

#Calculate CER / WER
echo "CER not tagged" >> $WorkDir/results_gw.txt
compute-wer --mode=present ark:${CharDir}/not_tagged_char.total.txt ark:${TmpDir}/decode/lattices/not_tagged_hypotheses-test_t | grep WER | sed -r 's|%WER|%CER|g' >> $WorkDir/results_gw.txt

echo "Separate WER not tagged" >> $WorkDir/results_gw.txt
compute-wer --mode=present ark:not_tagged_SeparateSimbols-word.txt ark:not_tagged_SeparateSimbols-wordtest.txt >> $WorkDir/results_gw.txt

#Macro P/R/F1 at line-level 
python $ScriptsDir/macro_edit_dist_tag_f1.py $TmpDir/tagging_symb.txt $TmpDir/test.lst \
$WorkDir/PREC-REC/ALT_NOT_PARENTHESIZED_NER-GT/ $WorkDir/PREC-REC/ALT_NOT_PARENTHESIZED_NER-DECODE/ >> $WorkDir/results_gw.txt

