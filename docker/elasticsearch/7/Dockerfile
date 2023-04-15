FROM docker.elastic.co/elasticsearch/elasticsearch:7.7.0
RUN bin/elasticsearch-plugin install analysis-icu
RUN bin/elasticsearch-plugin install analysis-phonetic
ADD elasticsearch.yml /usr/share/elasticsearch/config/elasticsearch.yml
