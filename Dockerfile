FROM vbosch/htr-machine:latest
RUN apt update
RUN apt install -y --fix-missing bc python-pip
RUN pip2 install scipy
WORKDIR /pidocs-soft/PyLaia/
RUN . /root/.bashrc && conda init bash && conda activate pylaia && pip install -r requirements.txt
COPY build-resource/* /pidocs-soft/PyLaia/
RUN mkdir -p /root/directorioTrabajo
VOLUME  /root/directorioTrabajo/
RUN . /root/.bashrc && conda init bash && pip install -r /pidocs-soft/PyLaia/requirements.txt
RUN apt-get install -y locales && locale-gen en_US.UTF-8
RUN apt-get install graphviz
ENV LANG='en_US.UTF-8' LANGUAGE='en_US:en' LC_ALL='en_US.UTF-8'
#INSTALAR SRILM
RUN mkdir /opt/srilm
WORKDIR /opt/srilm
COPY srilm-1.7.3.tar.gz .
RUN tar xzvf srilm-1.7.3.tar.gz && sed -i '1iSRILM = /opt/srilm' Makefile && \
make && make World
WORKDIR /root/
RUN pip install torchaudio
#RUN git clone --recursive https://github.com/parlance/ctcdecode.git && \
#cd ./ctcdecode && pip install .

COPY ./requirements.txt /root/requirements.txt
WORKDIR /root/
RUN pip install -r requirements.txt

RUN git clone https://github.com/NVIDIA/apex
WORKDIR /root/apex/
RUN pip install -v --disable-pip-version-check --no-cache-dir --global-option="--cpp_ext" --global-option="--cuda_ext" ./


#Dejar abierto el puerto 8080 para abrir notebooks
#EXPOSE 8080/tcp
#EXPOSE 8080/udp

#Ajuste PATH para incluir scripts y srilm
ENV PATH="/root/directorioTrabajo/TFM-NER/scripts/:/opt/srilm/lm/bin/i686-m64/:${PATH}"

#Arrancar bash en la carpeta que toque
WORKDIR /root/directorioTrabajo/DOC-NER/ 
CMD . /root/.bashrc && conda init bash && bash
# sudo docker build --rm  . -t hunterfinal
# sudo docker run --rm -v /pathLocalDelPC/directorioTrabajo/:/root/directorioTrabajo -it --gpus all --shm-size="16g" hunterfinal
# conda activate pylaia
