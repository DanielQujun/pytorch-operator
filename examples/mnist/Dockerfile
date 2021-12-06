FROM pytorch/pytorch:1.0-cuda10.0-cudnn7-runtime

RUN pip install tensorboardX==1.6.0 -i https://pypi.tuna.tsinghua.edu.cn/simple
RUN mkdir -p /opt/mnist

WORKDIR /opt/mnist/src
ADD mnist.py /opt/mnist/src/mnist.py

RUN  chgrp -R 0 /opt/mnist \
  && chmod -R g+rwX /opt/mnist

ADD data/ /opt/mnist/data/

ENTRYPOINT ["python", "/opt/mnist/src/mnist.py"]
