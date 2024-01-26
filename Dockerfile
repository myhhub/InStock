# 基础镜像
# https://hub.docker.com/_/python/tags?page=1&name=3.11-rc-rc-slim
FROM continuumio/miniconda3:latest

MAINTAINER myh
#增加语言utf-8
ENV LANG=zh_CN.UTF-8
ENV LC_CTYPE=zh_CN.UTF-8
ENV LC_ALL=C
ENV PYTHONPATH=/data/InStock
ENV CONDA_DIR=/opt/conda
ENV PATH=${CONDA_DIR}/bin:${PATH}
EXPOSE 9988

# 使用使用国内镜像地址加速。修改debian apt更新地址，pip地址，设置时区
# https://opsx.alibaba.com/mirror
# https://mirrors.tuna.tsinghua.edu.cn/help/pypi/
# cat /etc/apt/sources.list 参考原始地址，再确定怎么样替换
# 安装 依赖库
# apt-get autoremove -y 删除没有用的依赖lib
# apt-get --purge remove 软件包名称 , 删除已安装包（不保留配置文件)
# RUN sed -i "s@http://\(deb\|security\).debian.org@https://mirrors.aliyun.com@g" /etc/apt/sources.list && \
#     echo  "[global]\n\
# index-url = https://pypi.tuna.tsinghua.edu.cn/simple\n\
# trusted-host = pypi.tuna.tsinghua.edu.cn" > /etc/pip.conf  
RUN ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    echo "Asia/Shanghai" > /etc/timezone && \
    apt-get update && \
    rm -rf /root/.cache/* && rm -rf /var/lib/apt/lists/* && apt-get clean && apt-get autoclean && apt-get autoremove -y && \
    conda install -c conda-forge requests arrow numpy SQLAlchemy PyMySQL psycopg2 Logbook  tqdm beautifulsoup4  bokeh  pandas tornado ta-lib -y && \
    pip install supervisor && \
    pip install python_dateutil && \
    pip install py_mini_racer && \
    pip install easytrader && \
    conda clean --tarballs --index-cache --packages --yes && \
    conda clean --force-pkgs-dirs --all --yes  

WORKDIR /data
#InStock软件
COPY ./instock /data/InStock
COPY ./cron/cron.hourly /etc/cron.hourly
COPY ./cron/cron.workdayly /etc/cron.workdayly
COPY ./cron/cron.monthly /etc/cron.monthly

#add cron sesrvice.
#任务调度
RUN chmod 755 /data/InStock/instock/bin/run_*.sh && \
    chmod 755 /etc/cron.hourly/* && chmod 755 /etc/cron.workdayly/* && chmod 755 /etc/cron.monthly/* && \
    echo "SHELL=/bin/sh \n\
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin \n\
# min hour day month weekday command \n\
*/30 9,10,11,13,14,15 * * 1-5 /bin/run-parts /etc/cron.hourly \n\
30 17 * * 1-5 /bin/run-parts /etc/cron.workdayly \n\
30 10 * * 3,6 /bin/run-parts /etc/cron.monthly \n" > /var/spool/cron/crontabs/root && \
    chmod 600 /var/spool/cron/crontabs/root

ENTRYPOINT ["supervisord","-n","-c","/data/InStock/supervisor/supervisord.conf"]
