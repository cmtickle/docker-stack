FROM docker.elastic.co/elasticsearch/elasticsearch:6.8.13
RUN bin/elasticsearch-plugin install analysis-icu
RUN bin/elasticsearch-plugin install analysis-phonetic
ADD elasticsearch.yml /usr/share/elasticsearch/config/elasticsearch.yml

