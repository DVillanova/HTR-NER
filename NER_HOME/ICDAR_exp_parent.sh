# set -e
export LC_NUMERIC=C.UTF-8;

conda activate pylaia

#Varables, parameters and routes for Docker
GPU=1
BatchSize=8
WorkDir=/root/directorioTrabajo/DOC-NER/HTR-NER/NER_HOME/
ScriptsDir=/root/directorioTrabajo/DOC-NER/HTR-NER/scripts/
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

##Los directorios con los datos están en el NAS
#czech_charters -> /tmp/NAS/corpora/HOME/czech-NACR-44923-200121/
#german_charters -> /tmp/NAS/corpora/HOME/german-NACR-44923-200121/
#latin_charters -> /tmp/NAS/corpora/HOME/latin-NACR-44925-200121/
#ln -s /home/dvillanova/...
#czech_charters -> /home/dvillanova/...

########################################################################################
##Se extraen las lineas -- COMENTADO PORQUE SOLO EJECUTAR UNA VEZ

# source htrsh.inc.sh 

# textFeats_cfg='
# TextFeatExtractor: {
#   type            = "raw";
#   format          = "img";
#   fpgram          = true;
#   fcontour        = true;
#   fcontour_dilate = 0;
#   padding         = 12;
#   normheight      = 64;
#   momentnorm      = true;
#   enh_win         = 30;
#   enh_prm         = [ 0.1, 0.2, 0.4 ];
# }';

# export htrsh_valschema="no"

# D=`pwd`
# for f in ${DataDir}/czech_charters/*/*/page/*xml; do
#     n=`basename $f`; 
#     cd `dirname $f`; 
#     ln -s ../${n/.xml/.jpg} .
#     cd $D;
# done

# for f in ${DataDir}/german_charters/*/*/page/*xml; do
#     n=`basename $f`;
#     cd `dirname $f`;
#     ln -s ../${n/.xml/.jpg};
#     ln -s ../${n/.xml/.JPG};
#     cd $D;
# done

# for f in ${DataDir}/latin_charters/*/*/page/*xml; do
#     n=`basename $f`;
#     cd `dirname $f`;
#     ln -s ../${n/.xml/.jpg};
#     cd $D;
# done


# for i in ${DataDir}/czech_charters/*/*/page/*xml; do
#   textFeats --cfg <( echo "$textFeats_cfg" ) --outdir `dirname $i` $i
# done

# for i in ${DataDir}/german_charters/*/*/page/*xml; do
#   textFeats --cfg <( echo "$textFeats_cfg" ) --outdir `dirname $i` $i
# done

# for i in ${DataDir}/latin_charters/*/*/page/*xml; do
#   textFeats --cfg <( echo "$textFeats_cfg" ) --outdir `dirname $i` $i
# done



# cd ${DataDir}/czech_charters
# for f in */*xml; do awk '{if(($0~"url") && ($0~"facs_1_") && ($0~"TextRegion")){for(i=1;i<=NF;i++){if($i~"url"){gsub("url=\"","",$i);gsub(".jpg\"","",$i); url=$i}}} if($0~"<lb facs="){gsub("<lb facs=\"#facs_1_",url".",$0); print $0}}' $f | sed 's/\" n=\"N...\"\/>/ /g' | sed 's/<date .* continued=\"true\">/<date>/g'  | sed 's/<\/p>.*//g' ; done  | sed 's/            //g' | sed 's/<placeName\/>//g' | sed 's/<date [^>]*>/<date>/g'  > index.words-czech

# cd ${DataDir}/latin_charters
# for f in */*xml; do awk '{if(($0~"url") && ($0~"facs_1") && ($0~"TextRegion")){for(i=1;i<=NF;i++){if($i~"url"){gsub("url=\"","",$i);gsub(".jpg\"","",$i); url=$i}}} if($0~"<lb facs="){gsub("<lb facs=\"#facs_1_",url".",$0); print $0}}' $f | sed 's/\" n=\"N...\"\/>/ /g' | sed 's/<date .* continued=\"true\">/<date>/g'  | sed 's/<\/p>.*//g' ; done  | sed 's/            //g' | sed 's/<placeName\/>//g'  | sed 's/<date [^>]*>/<date>/g' > index.words-latin

# cd ${DataDir}/german_charters
# for f in */*xml; do awk '{if(($0~"url") && ($0~"facs_1") && ($0~"TextRegion")){for(i=1;i<=NF;i++){if($i~"url"){gsub("url=\"","",$i);gsub(".jpg\"","",$i); url=$i}}} if($0~"<lb facs="){gsub("<lb facs=\"#facs_1_",url".",$0); print $0}}' $f | sed 's/\" n=\"N...\"\/>/ /g' | sed 's/<date .* continued=\"true\">/<date>/g'  | sed 's/<\/p>.*//g' ; done  | sed 's/            //g' | sed 's/<placeName\/>//g' | sed 's/<date [^>]*>/<date>/g' > index.words-german

# sed 's/.JPG"//g' -i index.words-german



# cd ..

# ls czech_charters/*/*/page/*png > line-index
# ls german_charters/*/*/page/*png >> line-index
# ls latin_charters/*/*/page/*png >> line-index


# mkdir ${PartDir}
# cd ${PartDir}

# mv ${DataDir}/line-index .
# sed 's/page\///g' -i  line-index

#Esta parte no debería hacer falta porque los .lst ya los tengo
# for f in $(<../split/train_split.txt); do grep ${f/.xml/}"." line-index; done  > train-lines.lst
# for f in $(<../split/val_split.txt); do grep ${f/.xml/}"." line-index; done  > val-lines.lst
# for f in $(<../split/test_split.txt); do grep ${f/.xml/}"." line-index; done  > test-lines.lst

# for f in $(<train-lines.lst); do echo `dirname $f`"/page/"`basename $f`; done > k; mv k train-lines.lst
# for f in $(<val-lines.lst); do echo `dirname $f`"/page/"`basename $f`; done > k; mv k val-lines.lst
# for f in $(<test-lines.lst); do echo `dirname $f`"/page/"`basename $f`; done > k; mv k test-lines.lst

##################################################################################################################################################################################
#PREPARACIÓN FICHEROS SIN SUFIJOS
# rm ${PartDir}/"test".lst
# for f in $(<${PartDir}/test-lines.lst)
# do
#   f_alt=${f%%.png}
#   echo ${f_alt} >> ${PartDir}/"test".lst
# done

# rm ${PartDir}/val.lst
# for f in $(<${PartDir}/val-lines.lst)
# do
#   f_alt=${f%%.png}
#   echo ${f_alt} >> ${PartDir}/val.lst
# done

# rm ${PartDir}/train.lst
# for f in $(<${PartDir}/train-lines.lst)
# do
#   f_alt=${f%%.png}
#   echo ${f_alt} >> ${PartDir}/train.lst
# done

#Generar {train, test, val}.lst
python3 $ScriptsDir/ner_lst_generator.py ${PartDir}/OLD-PART/train.lst ${PartDir}/train.lst
python3 $ScriptsDir/ner_lst_generator.py ${PartDir}/OLD-PART/test.lst ${PartDir}/test.lst
python3 $ScriptsDir/ner_lst_generator.py ${PartDir}/OLD-PART/val.lst ${PartDir}/val.lst


# PREPARACIÓN DIRECTORIO "ALL_LINES" EN DATA/ALL_LINES --> SOLO 1 VEZ
#No debería hacer falta
#NO FUNCIONA PORQUE FALTAN FICHEROS DE LATIN?
# [ -d ${DataDir}/ALL_LINES ] ||
# {
#   mkdir ${DataDir}/ALL_LINES
#   for f in $(<${PartDir}/test-lines.lst)
#   do
#     cp ${DataDir}/${f} ${DataDir}/ALL_LINES
#     #cp ${DataDir}/${f}.txt ${DataDir}/ALL_LINES
#   done

#   for f in $(<${PartDir}/train-lines.lst)
#   do
#     cp ${DataDir}/${f} ${DataDir}/ALL_LINES
#     #cp ${DataDir}/${f}.txt ${DataDir}/ALL_LINES
#   done

#   for f in $(<${PartDir}/val-lines.lst)
#   do
#     cp ${DataDir}/${f} ${DataDir}/ALL_LINES
#     #cp ${DataDir}/${f}.txt ${DataDir}/ALL_LINES
#   done
# }

##################################################################################################################################################################################
rm -rf ${TextDir}
mkdir ${TextDir}
cd ${TextDir}

#CREACIÓN DE LOS INDEX.WORDS (FICHEROS CON TRANSCRIPCIÓN + ETIQUETAS)
#ELIMINAR PARTE URL:'...' Y .JPG AL FINAL        
for f in ${DataDir}/czech_charters/*/*xml
do 
#dir=`dirname $f`
dir=${f%%.xml}
awk -v d="$dir" '{
if(($0~"url") && ($0~"facs_1_") && ($0~"TextRegion")){
  for(i=1;i<=NF;i++){
    if($i~"url"){
      gsub("url=\"","",$i);
      gsub(".jpg\"","",$i);
	      url=$i
    }
  }
}
if($0~"<lb facs="){
	  gsub("<lb facs=\"#facs_1_",url".",$0);
  print $0
}
}' $f | sed 's/\" n=\"N...\"\/>/ /g' | sed 's/<date .* continued=\"true\">/<date>/g'  | sed 's/<\/p>.*//g' ; done  | sed 's/            //g' | sed 's/<placeName\/>//g' | sed 's/<date [^>]*>/<date>/g'  > index.words-czech

for f in ${DataDir}/latin_charters/*/*xml; do dir=${f%%.xml}; awk -v d="$dir" '{
if(($0~"url") && ($0~"facs_1") && ($0~"TextRegion")){
  for(i=1;i<=NF;i++){
    if($i~"url"){
      gsub("url=\"","",$i);gsub(".jpg\"","",$i); url=$i
    }
  }
} 
if($0~"<lb facs="){gsub("<lb facs=\"#facs_1_",url".",$0); print $0}}' $f | sed 's/\" n=\"N...\"\/>/ /g' | sed 's/<date .* continued=\"true\">/<date>/g'  | sed 's/<\/p>.*//g' ; done  | sed 's/            //g' | sed 's/<placeName\/>//g'  | sed 's/<date [^>]*>/<date>/g' > index.words-latin

for f in ${DataDir}/german_charters/*/*xml; do dir=${f%%.xml}; awk -v d="$dir" '{
if(($0~"url") && ($0~"facs_1") && ($0~"TextRegion")){
  for(i=1;i<=NF;i++){
    if($i~"url"){
      gsub("url=\"","",$i);gsub(".jpg\"","",$i); url=$i
    }
  }
} 
if($0~"<lb facs="){gsub("<lb facs=\"#facs_1_",url".",$0); print $0}}' $f | sed 's/\" n=\"N...\"\/>/ /g' | sed 's/<date .* continued=\"true\">/<date>/g'  | sed 's/<\/p>.*//g' ; done  | sed 's/            //g' | sed 's/<placeName\/>//g' | sed 's/<date [^>]*>/<date>/g' > index.words-german

sed 's/.JPG"//g' -i index.words-german

#Amontonar todos los index.words en uno y preproceso
cat index.words-* > index.words
sed 's/<add>//g' index.words | sed 's/<\/add>//g' | sed 's/<unclear>//g' | sed 's/<\/unclear>//g' | sed 's/<sic>//g' | sed 's/<\/sic>//g' | sed 's/<comment>//g' | sed 's/<\/comment>//g' | sed 's/<persName\/>//g' | sed 's/<blackening>//g' | sed 's/<\/blackening>//g' > k; mv k index.words 

sed 's/<gap\/>//g' index.words | sed 's/<hi .*kerning:0;\">//g' | sed 's/<\/hi>//g' | sed 's/<part-person>/<persName>/g' | sed 's/<person-part>/<persName>/g' | sed 's/<\/part-person>/<\/persName>/g' | sed 's/<\/person-part>/<\/persName>/g' > k; mv k index.words 


awk '{if(NF==1) print $0" <space>"; else print $0}' index.words  > kk; mv kk index.words

sed 's/</ </g' -i index.words
sed 's/>/> /g' -i index.words


#Postprocesado de cada index.words
for f in index.words; do
	echo "Procesado de " ${f}
sed 's/Č/C/g' -i $f; #Cambiar por c
echo "Č"
# sed 's/¡/!/g' -i $f; #Cambiar por !
# echo "¡"
# sed 's/¤//g' -i $f; #Eliminar
# echo "¤"
# sed 's/¦//g' -i $f;
# echo "¦"
# sed 's/©/(c)/g' -i $f; #Cambiar copyright por (c)
# echo "©"
# sed 's/¬/-|/g' -i $f; #Cambiar el not por -|
# echo "¬"
# sed 's/¯/-/g' -i $f; #Cambiar guión alto por medio
# echo "¯"
# sed 's/¶//g' -i $f; #Eliminar
# echo "¶"
# sed 's/¼/1\/4/g' -i $f; 
# echo "¼"
# sed 's/"½"/1\/2/g' -i $f;
# echo "½"
# sed 's/¿/?/g' -i $f;
# echo "¿"
# sed 's/Â/^A/g' -i $f;
# echo "Â"
# sed 's/Ã/~A/g' -i $f;
# echo "Ã"
# sed 's/Å/ºA/g' -i $f;
# echo "Å"
# sed 's/â/^a/g' -i $f;
# echo "â"
done

# Create data dir
cd ${WorkDir}
rm -rf ${CharDir}
mkdir -p ${CharDir}
cd ${CharDir}

# NO DEBERÍA HACER FALTA --> SE USA DESPUÉS EN LM
#CADA SUBCONJUNTO DE DATOS (TRAIN, VAL, TEST)
cat ${TextDir}/index.words | awk '{
      printf("%s ", $1);
      for(i=2;i<=NF;++i) {
              if($i!~"\<"){ 
                      for(j=1;j<=length($i);++j) 
                              printf(" %s", substr($i, j, 1));
                      if ((i < NF) && ($(i+1)!~"\<")) printf(" <space>");
              }else{ 
                      if (($(i-1)~"\<")) printf(" <space>");
                      printf " "$i" ";
              }; 
      }
      printf("\n");
}' | sed 's/"/'\'' '\''/g;s/#/<stroke>/g' > char.total.txt

#Extraer vocaboluario y número de símbolos en el vocabulario
cat char.total.txt | cut -f 2- -d\  | tr \  \\n| sort -u -V | awk 'BEGIN{   N=0;   printf("%-12s %d\n", "<eps>", N++);   printf("%-12s %d\n", "<ctc>", N++);  }NF==1{  printf("%-12s %d\n", $1, N++);}' >  symb.txt
# NSYMBOLS=$(sed -n '${ s|.* ||; p; }' "symb.txt");

#PREPROCESO PARA CREACIÓN DE FICHEROS .TXT CON NOMBRE ARCHIVO Y TRANSCRIP.
#A PARTIR DE ARCHIVO INDEX.WORDS CON TODAS LAS PALABRAS Y .LST CON FICHEROS
#DE PARTICION --> VOLCAR TODO EN WorkDir/TMP/
rm -rf ${TmpDir}
mkdir ${TmpDir}
cd ${TmpDir}

cp ${PartDir}/test.lst ./test.lst
cp ${PartDir}/train.lst ./train.lst
cp ${PartDir}/val.lst ./val.lst

#ESTO NO HACE FALTA (AÑADIR RUTAS COMPLETAS) PORQUE PYLAIA USA IMG IDS
# cp ${PartDir}/test.lst ./test_kk.lst
# awk '{
#   gsub("czech_charters","/root/directorioTrabajo/TFM-NER/DATA/czech_charters",$0);
#   gsub("german_charters","/root/directorioTrabajo/TFM-NER/DATA/german_charters",$0);
#   gsub("latin_charters","/root/directorioTrabajo/TFM-NER/DATA/latin_charters",$0);
#   print $0
# }' test_kk.lst > test.lst
# rm test_kk.lst

# cp ${PartDir}/train.lst ./train_kk.lst
# awk '{
#   gsub("czech_charters","/root/directorioTrabajo/TFM-NER/DATA/czech_charters",$0);
#   gsub("german_charters","/root/directorioTrabajo/TFM-NER/DATA/german_charters",$0);
#   gsub("latin_charters","/root/directorioTrabajo/TFM-NER/DATA/latin_charters",$0);
#   print $0
# }' train_kk.lst > train.lst
# rm train_kk.lst

# cp ${PartDir}/val.lst ./val_kk.lst
# awk '{
#   gsub("czech_charters","/root/directorioTrabajo/TFM-NER/DATA/czech_charters",$0);
#   gsub("german_charters","/root/directorioTrabajo/TFM-NER/DATA/german_charters",$0);
#   gsub("latin_charters","/root/directorioTrabajo/TFM-NER/DATA/latin_charters",$0);
#   print $0
# }' val_kk.lst > val.lst
# rm val_kk.lst

for f in $(<./train.lst); do grep "${f}\b" ${TextDir}/index.words; done > ./train.txt
for f in $(<./test.lst); do grep "${f}\b" ${TextDir}/index.words; done > ./test.txt
for f in $(<./val.lst); do grep "${f}\b" ${TextDir}/index.words; done > ./val.txt

#Generación char.train, char.val, char.test -> SUSTITUIDO POR SCRIPTILLO EN PYTHON
# for f in $(<./train.lst); do grep "${f}\b" ${TextDir}/index.words; done | 
# awk '{
#   printf("%s", $1);
#   for(i=2;i<=NF;++i) {
#     if($i!~"\<"){ 
#       for(j=1;j<=length($i);++j) 
#               printf(" %s", substr($i, j, 1));
#       if ((i < NF) && ($(i+1)!~"\<")) printf(" <space>");
#     }else{ 
#       if (($(i-1)~"\<")) printf(" <space>");
#       printf " "$i" ";
#     }; 
#   }
#   printf("\n");
# }' | sed 's/"/'\'' '\''/g;s/#/<stroke>/g' | iconv -f iso8859-1 -t utf8 > char.train.txt

# for f in $(<./val.lst); do grep "${f}\b" ${TextDir}/index.words; done | 
# awk '{
#   printf("%s", $1);
#   for(i=2;i<=NF;++i) {
#     if($i!~"\<"){ 
#       for(j=1;j<=length($i);++j) 
#               printf(" %s", substr($i, j, 1));
#       if ((i < NF) && ($(i+1)!~"\<")) printf(" <space>");
#     }else{ 
#       if (($(i-1)~"\<")) printf(" <space>");
#       printf " "$i" ";
#     };
#   }
#   printf("\n");
# }' | sed 's/"/'\'' '\''/g;s/#/<stroke>/g' | iconv -f iso8859-1 -t utf8 > char.val.txt

# for f in $(<./test.lst); do grep "${f}\b" ${TextDir}/index.words; done | 
# awk '{
#   printf("%s", $1);
#   for(i=2;i<=NF;++i) {
#     if($i!~"\<"){ 
#       for(j=1;j<=length($i);++j) 
#               printf(" %s", substr($i, j, 1));
#       if ((i < NF) && ($(i+1)!~"\<")) printf(" <space>");
#     }else{ 
#       if (($(i-1)~"\<")) printf(" <space>");
#       printf " "$i" ";
#     };
#   }
#   printf("\n");
# }' | sed 's/"/'\'' '\''/g;s/#/<stroke>/g' | iconv -f iso8859-1 -t utf8 > char.test.txt

python3 $ScriptsDir/ner_char_splitter.py ./train.txt ./char.train.txt
sed 's/"/'\'' '\''/g;s/#/<stroke>/g' -i ./char.train.txt

python3 $ScriptsDir/ner_char_splitter.py ./val.txt ./char.val.txt
sed 's/"/'\'' '\''/g;s/#/<stroke>/g' -i ./char.val.txt

python3 $ScriptsDir/ner_char_splitter.py ./test.txt ./char.test.txt
sed 's/"/'\'' '\''/g;s/#/<stroke>/g' -i ./char.test.txt

#Símbolos con método Vicente
for p in train test val; do cat char.${p}.txt | cut -f 2- -d\  | tr \  \\n; done | sort -u -V | awk 'BEGIN{
N=0;
printf("%-12s %d\n", "<ctc>", N++);
}NF==1{
printf("%-12s %d\n", $1, N++);
}' >  symb.txt


cd ${WorkDir}
rm -rf ${ModelDir}
mkdir ${ModelDir}

#Creación del modelo óptico. 

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
--cnn_poolsize 2 2 0 2 \
--use_masked_conv=true \
--rnn_type LSTM \
--rnn_layers 3 \
--rnn_units 256 \
--rnn_dropout 0.5 \
--lin_dropout 0.5 \
3 ${TmpDir}/symb.txt

#Seleccionar todas las carpetas que contienen las líneas
#img_dirs=$(find ${DataDir}/*_charters -mindepth 4 -maxdepth 4 -type d)
#img_dirs=${DataDir}/*_charters/*/*/page/ #Alternativa

#Entrenamiento del modelo óptico.
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

#Aquí ponerse a hacer rutas completas es un cacao

#Decodificación de las imágenes de validación y test
#Para posterior cálculo de CER y WER

#laia-decode --batch_size 8  --symbols_table ../lang/char/symb.txt ../models/train.t7 ../PARTITIONS/val-lines.lst > va.txt
#laia-decode --batch_size 8  --symbols_table ../lang/char/symb.txt ../models/train.t7 ../PARTITIONS/test-lines.lst > test.txt

#DECODIFICACION TEST Y VAL PARA WER
#CER (SPACE = "<SPACE>", JOIN_STR = " ")
pylaia-htr-decode-ctc-rgb \
--print_args True \
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


# Get word-level transcript hypotheses (CALCULO WER A POSTERIORI)
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
# SOLO SE HA ACTUALIZADO LOS DIRECTORIOS
cd ${TmpDir}/decode
if $(which compute-wer &> /dev/null); then
#CALCULO CER
echo "test" > $WorkDir/res_exp.txt
compute-wer --mode=present ark:${CharDir}/char.total.txt ark:${TmpDir}/decode/test.txt | grep WER | sed -r 's|%WER|%CER|g' >> $WorkDir/res_exp.txt
echo "val" >> $WorkDir/res_exp.txt
compute-wer --mode=present ark:${CharDir}/char.total.txt ark:${TmpDir}/decode/va.txt | grep WER | sed -r 's|%WER|%CER|g' >> $WorkDir/res_exp.txt

#CALCULO WER
echo "test" >> $WorkDir/res_exp.txt
compute-wer --mode=present  ark:${CharDir}/word.total.txt ark:${TmpDir}/decode/wordtest.txt |  grep WER >> $WorkDir/res_exp.txt
echo "val" >> $WorkDir/res_exp.txt
compute-wer --mode=present  ark:${CharDir}/word.total.txt ark:${TmpDir}/decode/wordva.txt |  grep WER >> $WorkDir/res_exp.txt

echo "------------" >> $WorkDir/res_exp.txt

sed 's/\([.,:;?]\)/ \1/g;s/\([¿¡]\)/\1 /g' wordtest.txt > SeparateSimbols-wordtest.txt
sed 's/\([.,:;?]\)/ \1/g;s/\([¿¡]\)/\1 /g' corrected_wordtest.txt > SeparateSimbols-corrected_wordtest.txt
sed 's/\([.,:;?]\)/ \1/g;s/\([¿¡]\)/\1 /g' wordva.txt > SeparateSimbols-wordva.txt
sed 's/\([.,:;?]\)/ \1/g;s/\([¿¡]\)/\1 /g' ${CharDir}/word.total.txt > SeparateSimbols-word.txt
sed 's/ \.line/\.line/g;s/ \.r\([0-9]\)/\.r\1/g' -i SeparateSimbols-word.txt
sed 's/ \.line/\.line/g;s/ \.r\([0-9]\)/\.r\1/g' -i SeparateSimbols-wordtest.txt
sed 's/ \.line/\.line/g;s/ \.r\([0-9]\)/\.r\1/g' -i SeparateSimbols-corrected_wordtest.txt
sed 's/ \.line/\.line/g;s/ \.r\([0-9]\)/\.r\1/g' -i SeparateSimbols-wordva.txt

sed 's/</ </g;s/>/> /g' SeparateSimbols-word.txt | sed 's/  / /g' > k; mv k SeparateSimbols-word.txt
sed 's/</ </g;s/>/> /g' SeparateSimbols-wordtest.txt | sed 's/  / /g' > k; mv k SeparateSimbols-wordtest.txt
sed 's/</ </g;s/>/> /g' SeparateSimbols-corrected_wordtest.txt | sed 's/  / /g' > k; mv k SeparateSimbols-corrected_wordtest.txt
sed 's/</ </g;s/>/> /g' SeparateSimbols-wordva.txt | sed 's/  / /g' > k; mv k SeparateSimbols-wordva.txt


#Cálculo WER con la separación de los caracteres de arriba ^ (hola! -> hola !)
compute-wer --mode=present ark:SeparateSimbols-word.txt ark:SeparateSimbols-wordtest.txt >> $WorkDir/res_exp.txt
echo "------------" >> $WorkDir/res_exp.txt
compute-wer --mode=present ark:SeparateSimbols-word.txt ark:SeparateSimbols-wordva.txt >> $WorkDir/res_exp.txt
echo "------------" >> $WorkDir/res_exp.txt


rm Separate*

else
echo "ERROR: Kaldi's compute-wer was not found in your PATH!" >&2;
fi;


######################################################################################################
## Genero el GT de las NER

cd ${WorkDir}

mkdir ${NerDir}
cd ${NerDir}
cp ${TextDir}/index.words
$ScriptsDir/extractNER-GT.sh ${TextDir}index.words #Esto funciona? --> ./ cuando el .sh no está en ese dir.

cd -
mkdir ${NerNoRepDir}
cd ${NerNoRepDir}
$ScriptsDir/extractNER-GT-noRep.sh ${TextDir}/index.words #Esto funciona? --> ./ .sh no en dir.


########################################################################################################################
################# Incluir modelo de lenguaje ###########################################################################
########################################################################################################################

# Force alignment

#cd ${ModelDir}
#laia-force-align --batch_size "8"  --batcher_cache_gpu 1  --log_level info  --log_also_to_stderr info   train.t7 ../lang/char/symb.txt ../PARTITIONS/train-lines.lst ../lang/char/char.total.txt  align_output.txt priors.txt

# Obtaining confMats
cd ${TmpDir}/decode
#laia-netout --batch_size "8" --batcher_cache_gpu 1  --log_level info --log_also_to_stderr info --output_format matrix  --prior ../models/priors.txt --prior_alpha 0.3 ../models/train.t7 ../PARTITIONS/val-lines.lst confMats_ark-validation.txt
#laia-netout --batch_size "8" --batcher_cache_gpu 1  --log_level info --log_also_to_stderr info --output_format matrix  --prior ../models/priors.txt --prior_alpha 0.3 ../models/train.t7 ../PARTITIONS/test-lines.lst confMats_ark-test.txt
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

#LA GRAMÁTICA GENERADA ES PROBABILÍSTICA PERO PROBABILIDADES NO SUMAN 1 (SE USAN SCORES)
$ScriptsDir/prepare_lang_test-ds.sh lang/LM.arpa lang lang_test "$DUMMY_CHAR"


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

simplex.py -v -m "/root/directorioTrabajo/TFM-NER/scripts/opt_gsf-wip_cl.sh {$ASF} {$WIP}" > result-simplex
#/root/directorioTrabajo/TFM-NER/scripts/

ASF=1.27216049 
WIP=-0.76260881

$ScriptsDir/score.sh --wip $WIP --lmw $ASF $ModelDir/HMMs/test/graph/words.txt "ark:gzip -c -d lat-test.gz |" $LangDir/char/char.total.txt hypotheses-test 2>log


echo -e "\nGenerating file of hypotheses: hypotheses_t" 1>&2
int2sym.pl -f 2- $LangDir/lm/lang_test/words.txt hypotheses-test > hypotheses-test_t
int2sym.pl -f 2- $LangDir/lm/lang_test/words.txt hypotheses-validation > hypotheses-validation_t

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

# 2500-Best decoding
##################################
N=2500
cd $TmpDir/decode/lattices

cp ${LangDir}/lm/lang/words.txt ./words.txt

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

echo "==============" >> $WorkDir/res_exp.txt
echo "Resultados tras añadir LM" >> $WorkDir/res_exp.txt

echo "Resultados CON 2500-BEST decoding (CER)" >> $WorkDir/res_exp.txt
compute-wer --mode=present  ark:$LangDir/char/char.total.txt ark:./${N}-best-compliant-test-chars.txt | grep WER | sed -r 's|%WER|%CER|g' >> $WorkDir/res_exp.txt;

echo "Resultados CON 2500-BEST decoding (WER)" >> $WorkDir/res_exp.txt
sed 's/\([.,:;?]\)/ \1/g;s/\([¿¡]\)/\1 /g' ./${N}-best-compliant-test-words.txt > SeparateSimbols-wordtest.txt
sed 's/\([.,:;?]\)/ \1/g;s/\([¿¡]\)/\1 /g' $LangDir/char/word.total.txt > SeparateSimbols-word.txt
sed 's/ \.line/\.line/g;s/ \.r\([0-9]\)/\.r\1/g;s/ \.region/\.region/g' -i SeparateSimbols-word.txt
sed 's/ \.line/\.line/g;s/ \.r\([0-9]\)/\.r\1/g;s/ \.region/\.region/g' -i SeparateSimbols-wordtest.txt
sed 's/</ </g' SeparateSimbols-wordtest.txt | sed 's/>/> /g' | sed 's/  / /g' > k; mv k SeparateSimbols-wordtest.txt
sed 's/</ </g' SeparateSimbols-word.txt | sed 's/>/> /g' | sed 's/  / /g' > k; mv k SeparateSimbols-word.txt
compute-wer --mode=present ark:SeparateSimbols-word.txt ark:SeparateSimbols-wordtest.txt >> $WorkDir/res_exp.txt;

echo "=============" >> $WorkDir/res_exp.txt

#Compute CER/WER.
if $(which compute-wer &> /dev/null); then
echo "Test cer" >> $WorkDir/res_exp.txt
compute-wer --mode=present  ark:$LangDir/char/char.total.txt ark:hypotheses-test_t | grep WER | sed -r 's|%WER|%CER|g' >> $WorkDir/res_exp.txt;
echo "Test wer" >> $WorkDir/res_exp.txt
compute-wer --mode=present  ark:$LangDir/char/word.total.txt ark:word-lm/hyp_word-test.txt |  grep WER >> $WorkDir/res_exp.txt;

sed 's/\([.,:;?]\)/ \1/g;s/\([¿¡]\)/\1 /g' word-lm/hyp_word-test.txt > SeparateSimbols-wordtest.txt
sed 's/\([.,:;?]\)/ \1/g;s/\([¿¡]\)/\1 /g' $LangDir/char/word.total.txt > SeparateSimbols-word.txt
sed 's/ \.line/\.line/g;s/ \.r\([0-9]\)/\.r\1/g;s/ \.region/\.region/g' -i SeparateSimbols-word.txt
sed 's/ \.line/\.line/g;s/ \.r\([0-9]\)/\.r\1/g;s/ \.region/\.region/g' -i SeparateSimbols-wordtest.txt
sed 's/</ </g' SeparateSimbols-wordtest.txt | sed 's/>/> /g' | sed 's/  / /g' > k; mv k SeparateSimbols-wordtest.txt
sed 's/</ </g' SeparateSimbols-word.txt | sed 's/>/> /g' | sed 's/  / /g' > k; mv k SeparateSimbols-word.txt

echo "Test wer separate" >> $WorkDir/res_exp.txt
compute-wer --mode=present ark:SeparateSimbols-word.txt ark:SeparateSimbols-wordtest.txt >> $WorkDir/res_exp.txt

sed 's/\([.,:;?]\)/ \1/g;s/\([¿¡]\)/\1 /g' word-lm/combined_hyp_word-test.txt > SeparateSimbols-wordtest.txt
sed 's/ \.line/\.line/g;s/ \.r\([0-9]\)/\.r\1/g' -i SeparateSimbols-wordtest.txt
sed 's/</ </g' SeparateSimbols-wordtest.txt | sed 's/>/> /g' | sed 's/  / /g' > k; mv k SeparateSimbols-wordtest.txt

echo "--------------" >> $WorkDir/res_exp.txt
echo "Val cer" >> $WorkDir/res_exp.txt
compute-wer --mode=present  ark:$LangDir/char/char.total.txt ark:hypotheses-validation_t |   grep WER | sed -r 's|%WER|%CER|g' >> $WorkDir/res_exp.txt;

echo "Val wer" >> $WorkDir/res_exp.txt
compute-wer --mode=present  ark:$LangDir/char/word.total.txt ark:word-lm/hyp_word-validation.txt |  grep WER >> $WorkDir/res_exp.txt;

sed 's/\([.,:;?]\)/ \1/g;s/\([¿¡]\)/\1 /g' word-lm/hyp_word-validation.txt > SeparateSimbols-wordvalidation.txt
sed 's/ \.line/\.line/g;s/ \.r\([0-9]\)/\.r\1/g' -i SeparateSimbols-wordvalidation.txt
sed 's/</ </g' SeparateSimbols-wordvalidation.txt | sed 's/>/> /g' | sed 's/  / /g' > k; mv k SeparateSimbols-wordvalidation.txt

echo "Val wer separate" >> $WorkDir/res_exp.txt
compute-wer --mode=present ark:SeparateSimbols-word.txt ark:SeparateSimbols-wordvalidation.txt >> $WorkDir/res_exp.txt

rm Separate*

else
echo "ERROR: Kaldi's compute-wer was not found in your PATH!" >&2;
fi;

##########################################################################
## ORACLE METRICS

$ScriptsDir/oracle_transc.sh $TmpDir $LangDir/lm/lang $TmpDir/decode/lattices/

int2sym.pl -f 2- $LangDir/lm/lang_test/words.txt $TmpDir/decode/lattices/oracle_transc.txt > $TmpDir/decode/lattices/oracle_transc_t

#CALC CER WITH ORACLE_TRANSC
echo "ORACLE CER" >> $WorkDir/res_exp.txt
compute-wer --mode=present  ark:$lang/../../char/char.total.txt ark:$TmpDir/decode/lattices/oracle_transc_t | grep WER | sed -r 's|%WER|%CER|g' >> $WorkDir/res_exp.txt

#CALC WER
awk '{
printf("%s ", $1);
for (i=2;i<=NF;++i) {
  if ($i == "<space>")
    printf(" ");
  else
    printf("%s", $i);
}
printf("\n");
}' $TmpDir/decode/lattices/oracle_transc_t > $TmpDir/decode/lattices/word-lm/oracle_transc-test.txt;

sed 's/\([.,:;?]\)/ \1/g;s/\([¿¡]\)/\1 /g' $TmpDir/decode/lattices/word-lm/oracle_transc-test.txt > $TmpDir/decode/lattices/SeparateSimbols-wordtest.txt
sed 's/ \.line/\.line/g;s/ \.r\([0-9]\)/\.r\1/g' -i $TmpDir/decode/lattices/SeparateSimbols-wordtest.txt
sed 's/</ </g' $TmpDir/decode/lattices/SeparateSimbols-wordtest.txt | sed 's/>/> /g' | sed 's/  / /g' > k; mv k $TmpDir/decode/lattices/SeparateSimbols-wordtest.txt

echo "ORACLE WER (SEPARATE)" >> $WorkDir/res_exp.txt
compute-wer --mode=present ark:$TmpDir/decode/lattices/SeparateSimbols-word.txt ark:$TmpDir/decode/lattices/SeparateSimbols-wordtest.txt >> $WorkDir/res_exp.txt


##########################################################################
## EVALUACIÓN PRECISIÓN - RECALL

#In $TmpDir/decode/lattices
sed 's/\([.,:;?]\)/ \1/g;s/\([¿¡]\)/\1 /g' word-lm/hyp_word-test.txt > SeparateSimbols-wordtest.txt
sed 's/ \.line/\.line/g;s/ \.r\([0-9]\)/\.r\1/g;s/ \.region/\.region/g' -i SeparateSimbols-wordtest.txt
sed 's/</ </g' SeparateSimbols-wordtest.txt | sed 's/>/> /g' | sed 's/  / /g' > k; mv k SeparateSimbols-wordtest.txt


sed 's/\([.,:;?]\)/ \1/g;s/\([¿¡]\)/\1 /g' $LangDir/char/word.total.txt > SeparateSimbols-word.txt
sed 's/ \.line/\.line/g;s/ \.r\([0-9]\)/\.r\1/g;s/ \.region/\.region/g' -i SeparateSimbols-word.txt
sed 's/</ </g' SeparateSimbols-word.txt | sed 's/>/> /g' | sed 's/  / /g' > k; mv k SeparateSimbols-word.txt

cd $TmpDir
for f in $(<$PartDir/test.lst); do grep "${f}\b" ${TmpDir}/decode/lattices/SeparateSimbols-word.txt; done > ./SeparateSimbols-GT_test.txt



mkdir $WorkDir/PREC-REC
cd $WorkDir/PREC-REC/

#EVAL BASELINE WITH SEPARATE SYMBOLS
mkdir $WorkDir/PREC-REC/CONTINUOUS_NER-DECODE
cd $WorkDir/PREC-REC/CONTINUOUS_NER-DECODE
rm $WorkDir/PREC-REC/CONTINUOUS_NER-DECODE/*
python $ScriptsDir/extract_ner_parenthesized.py $TmpDir/decode/lattices/SeparateSimbols-wordtest.txt .
for f in *; do sed 's/^ //g' -i $f; done

cd ..

mkdir $WorkDir/PREC-REC/CONTINUOUS_NER-GT
cd $WorkDir/PREC-REC/CONTINUOUS_NER-GT
rm $WorkDir/PREC-REC/CONTINUOUS_NER-GT/*
python $ScriptsDir/extract_ner_parenthesized.py $TmpDir/SeparateSimbols-GT_test.txt .
for f in *; do sed 's/^ //g' -i $f; done

cd ..

echo "Baseline results" >> $WorkDir/res_exp.txt
python $ScriptsDir/calc_prec_rec.py ./CONTINUOUS_NER-GT ./CONTINUOUS_NER-DECODE >> $WorkDir/res_exp.txt
python $ScriptsDir/alt_dist_edicion_custom_saturated.py ./CONTINUOUS_NER-GT ./CONTINUOUS_NER-DECODE >> $WorkDir/res_exp.txt

#EVAL 2500-BEST

cd $TmpDir/decode/lattices/
sed 's/\([.,:;?]\)/ \1/g;s/\([¿¡]\)/\1 /g' ./${N}-best-compliant-test-words.txt > SeparateSimbols-wordtest.txt
sed 's/ \.line/\.line/g;s/ \.r\([0-9]\)/\.r\1/g;s/ \.region/\.region/g' -i SeparateSimbols-wordtest.txt
sed 's/</ </g' SeparateSimbols-wordtest.txt | sed 's/>/> /g' | sed 's/  / /g' > k; mv k SeparateSimbols-wordtest.txt

mkdir $WorkDir/PREC-REC/NER-2500-BEST 
cd $WorkDir/PREC-REC/NER-2500-BEST
rm $WorkDir/PREC-REC/NER-2500-BEST/*
python $ScriptsDir/extract_ner_parenthesized.py $TmpDir/decode/lattices/SeparateSimbols-wordtest.txt .
for f in *; do sed 's/^ //g' -i $f; done

cd ..

echo "2500-best results" >> $WorkDir/res_exp.txt
python $ScriptsDir/calc_prec_rec.py ./NER-GT ./NER-2500-BEST >> $WorkDir/res_exp.txt
python $ScriptsDir/alt_dist_edicion_custom_saturated.py ./NER-GT ./NER-2500-BEST >> $WorkDir/res_exp.txt